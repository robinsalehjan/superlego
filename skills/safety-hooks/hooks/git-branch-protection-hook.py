#!/usr/bin/env python3
"""
PreToolUse hook for git branch protection.
Prevents committing directly to main/master, merging without approval,
and deleting release tags.

This hook asks for user confirmation when:
  - Committing while on main/master branch
  - Pushing to main/master branch
  - Merging into main/master branch
  - Merging a PR via gh cli
  - Deleting release tags (v*, release-*)

Output:
  Exit 0 = allow
  JSON with "decision": "ask" = prompt user for confirmation
"""
import re
import subprocess

from hook_utils import (
    parse_input,
    output_allow,
    output_ask,
    normalize_command,
    load_config,
)

# Default protected branches (can be overridden in config)
DEFAULT_PROTECTED_BRANCHES = ["main", "master"]
DEFAULT_PROTECTED_TAG_PREFIXES = ["v", "release-"]


def get_config():
    """Get git protection config with defaults."""
    config = load_config()
    git_config = config.get("git_protection", {})
    return {
        "protected_branches": git_config.get("protected_branches", DEFAULT_PROTECTED_BRANCHES),
        "protected_tag_prefixes": git_config.get("protected_tag_prefixes", DEFAULT_PROTECTED_TAG_PREFIXES),
        "ask_on_merge_to_protected": git_config.get("ask_on_merge_to_protected", True),
        "ask_on_tag_delete": git_config.get("ask_on_tag_delete", True),
    }


def get_current_branch() -> str | None:
    """Get the current git branch name, or None if not in a git repo."""
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return None


def check_commit_on_protected_branch(command: str, current_branch: str | None, config: dict) -> tuple[str, str]:
    """Check if this is a commit on a protected branch."""
    if not re.search(r"\bgit\s+commit\b", command, re.IGNORECASE):
        return "allow", ""

    protected = config["protected_branches"]
    if current_branch in protected:
        return "ask", f"committing directly to '{current_branch}' branch"

    return "allow", ""


def check_push_to_protected_branch(command: str, current_branch: str | None, config: dict) -> tuple[str, str]:
    """Check if pushing to a protected branch."""
    push_match = re.search(r"\bgit\s+push\b(.*)$", command, re.IGNORECASE)
    if not push_match:
        return "allow", ""

    push_args = push_match.group(1).strip()
    protected = config["protected_branches"]

    # Check for explicit push to protected branch: git push origin main
    for branch in protected:
        if re.search(rf"\b{re.escape(branch)}\b", push_args):
            return "ask", f"pushing to '{branch}' branch"

    # Check for push without explicit branch (uses current branch)
    if not push_args or re.match(r"^(-[a-zA-Z]+\s+)*\w+$", push_args):
        if current_branch in protected:
            return "ask", f"pushing to '{current_branch}' branch (current branch)"

    return "allow", ""


def check_merge_to_protected_branch(command: str, current_branch: str | None, config: dict) -> tuple[str, str]:
    """Check if merging into a protected branch."""
    if not config.get("ask_on_merge_to_protected", True):
        return "allow", ""

    # Check for git merge command
    if not re.search(r"\bgit\s+merge\b", command, re.IGNORECASE):
        return "allow", ""

    protected = config["protected_branches"]

    # If we're on a protected branch and merging something into it
    if current_branch in protected:
        return "ask", f"merging into '{current_branch}' branch"

    return "allow", ""


def check_pr_merge(command: str) -> tuple[str, str]:
    """Check if merging a PR via gh cli."""
    if re.search(r"\bgh\s+pr\s+merge\b", command, re.IGNORECASE):
        return "ask", "merging PR to target branch"

    return "allow", ""


def check_tag_delete(command: str, config: dict) -> tuple[str, str]:
    """Check if deleting a release tag."""
    if not config.get("ask_on_tag_delete", True):
        return "allow", ""

    # Check for git tag -d or git tag --delete
    tag_delete_match = re.search(r"\bgit\s+tag\s+.*(-d|--delete)\s+(.+)", command, re.IGNORECASE)
    if not tag_delete_match:
        # Also check: git push origin --delete tag-name (for remote tag deletion)
        push_delete_match = re.search(r"\bgit\s+push\s+\w+\s+--delete\s+(.+)", command, re.IGNORECASE)
        if not push_delete_match:
            # Also check: git push origin :refs/tags/tag-name
            push_ref_match = re.search(r"\bgit\s+push\s+\w+\s+:refs/tags/(.+)", command, re.IGNORECASE)
            if not push_ref_match:
                return "allow", ""
            tag_name = push_ref_match.group(1).strip()
        else:
            tag_name = push_delete_match.group(1).strip()
    else:
        tag_name = tag_delete_match.group(2).strip()

    # Check if tag matches protected prefixes
    protected_prefixes = config["protected_tag_prefixes"]
    for prefix in protected_prefixes:
        if tag_name.startswith(prefix):
            return "ask", f"deleting release tag '{tag_name}'"

    return "allow", ""


def check_command(command: str) -> tuple[str, str]:
    """
    Check command for protected branch operations.
    Returns: (decision, message)
    """
    command = normalize_command(command)

    # Early exit: skip git subprocess for non-git commands
    if not re.search(r"\b(git|gh)\b", command, re.IGNORECASE):
        return "allow", ""

    config = get_config()

    # Check PR merge first (doesn't need branch info)
    decision, message = check_pr_merge(command)
    if decision != "allow":
        return decision, message

    # Check tag deletion
    decision, message = check_tag_delete(command, config)
    if decision != "allow":
        return decision, message

    # Cache current branch for remaining checks (single git call)
    current_branch = get_current_branch()

    # Check commit, push, and merge with cached branch
    for checker in [check_commit_on_protected_branch, check_push_to_protected_branch, check_merge_to_protected_branch]:
        decision, message = checker(command, current_branch, config)
        if decision != "allow":
            return decision, message

    return "allow", ""


def main():
    hook_input = parse_input()
    if not hook_input:
        output_allow()

    if hook_input.tool_name != "Bash":
        output_allow()

    command = hook_input.tool_input.get("command", "")
    if not command:
        output_allow()

    decision, message = check_command(command)

    if decision == "ask":
        output_ask(f"Branch protection: {message}")
    else:
        output_allow()


if __name__ == "__main__":
    main()
