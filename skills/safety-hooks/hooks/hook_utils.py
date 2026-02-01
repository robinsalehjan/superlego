#!/usr/bin/env python3
"""
Shared utilities for safety hooks.

Provides common functionality:
- JSON input parsing
- Decision output formatting
- Pattern compilation and matching
- Configuration loading
"""
import json
import os
import re
import sys
from pathlib import Path
from typing import NamedTuple


class Pattern(NamedTuple):
    """A compiled pattern with its message."""
    regex: re.Pattern
    message: str


class HookInput(NamedTuple):
    """Parsed input from Claude Code."""
    tool_name: str
    tool_input: dict
    session_id: str
    cwd: str


def parse_input() -> HookInput | None:
    """
    Parse JSON input from stdin.
    Returns None if parsing fails or input is invalid.
    """
    try:
        data = json.load(sys.stdin)
        return HookInput(
            tool_name=data.get("tool_name", ""),
            tool_input=data.get("tool_input", {}),
            session_id=data.get("session_id", ""),
            cwd=data.get("cwd", ""),
        )
    except (json.JSONDecodeError, AttributeError):
        return None


def output_allow() -> None:
    """Exit with allow decision (exit code 0, no output)."""
    sys.exit(0)


def output_block(message: str) -> None:
    """Exit with block decision (exit code 2, message to stderr)."""
    print(f"BLOCKED: {message}", file=sys.stderr)
    sys.exit(2)


def output_ask(reason: str) -> None:
    """Exit with ask decision (exit code 0, JSON to stdout)."""
    response = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": reason,
        }
    }
    print(json.dumps(response))
    sys.exit(0)


def output_warn(message: str) -> None:
    """Output warning and allow (exit code 0, message to stderr)."""
    print(f"Warning: {message}", file=sys.stderr)
    sys.exit(0)


def compile_patterns(patterns: list[tuple[str, str]]) -> list[Pattern]:
    """
    Compile a list of (pattern_str, message) tuples into Pattern objects.
    Patterns are compiled with IGNORECASE flag.
    """
    compiled = []
    for pattern_str, message in patterns:
        try:
            compiled.append(Pattern(
                regex=re.compile(pattern_str, re.IGNORECASE),
                message=message
            ))
        except re.error as e:
            print(f"Warning: Invalid pattern '{pattern_str}': {e}", file=sys.stderr)
    return compiled


def match_patterns(text: str, patterns: list[Pattern]) -> tuple[bool, str]:
    """
    Check if text matches any pattern.
    Returns (matched, message) tuple.
    """
    for pattern in patterns:
        if pattern.regex.search(text):
            return True, pattern.message
    return False, ""


def match_allowlist(text: str, patterns: list[re.Pattern]) -> bool:
    """Check if text matches any allowlist pattern."""
    for pattern in patterns:
        if pattern.search(text):
            return True
    return False


def compile_allowlist(patterns: list[str]) -> list[re.Pattern]:
    """Compile allowlist patterns."""
    compiled = []
    for pattern_str in patterns:
        try:
            compiled.append(re.compile(pattern_str, re.IGNORECASE))
        except re.error as e:
            print(f"Warning: Invalid allowlist pattern '{pattern_str}': {e}", file=sys.stderr)
    return compiled


def load_config() -> dict:
    """
    Load configuration from config.json in the hooks directory.
    Returns empty dict if file doesn't exist or is invalid.
    """
    config_path = Path(__file__).parent / "config.json"
    if not config_path.exists():
        return {}

    try:
        with open(config_path) as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        print(f"Warning: Failed to load config: {e}", file=sys.stderr)
        return {}


def normalize_command(command: str) -> str:
    """
    Normalize command for consistent pattern matching.
    Converts /usr/bin/git to git, /bin/rm to rm, etc.
    """
    # Common command paths to normalize
    commands = r"git|gh|rm|dd|mkfs|curl|wget|docker|pkill|killall|crontab|npm|yarn|pnpm|pip|chmod|chown|nc|netcat|env|printenv"
    return re.sub(rf"(/usr)?/(s?bin)/({commands})\b", r"\3", command)


def normalize_path(path: str) -> str:
    """
    Normalize file path for consistent pattern matching.
    Expands ~, resolves ../ traversal, and cleans up.
    """
    if path.startswith("~"):
        path = os.path.expanduser(path)
    return os.path.normpath(path)
