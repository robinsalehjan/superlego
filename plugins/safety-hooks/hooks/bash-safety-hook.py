#!/usr/bin/env python3
"""
PreToolUse hook for Bash commands.
Runs BEFORE Claude executes any Bash command, even with --dangerously-skip-permissions.

Three levels:
  ALWAYS_BLOCK - Catastrophic, never allow (rm -rf /, dd to devices, etc.)
  ASK_PATTERNS - Dangerous but sometimes legitimate, prompt user
  WARN_PATTERNS - Just log a warning, allow

Safe patterns (ALLOWLIST) are checked first and bypass all restrictions.

Output:
  Exit 0 = allow
  Exit 2 = block
  JSON with "decision": "ask" = prompt user for confirmation
"""
from hook_utils import (
    parse_input,
    output_allow,
    output_block,
    output_ask,
    output_warn,
    compile_patterns,
    compile_allowlist,
    match_patterns,
    match_allowlist,
    normalize_command,
    load_config,
)

# =============================================================================
# ALLOWLIST - Safe patterns that bypass restrictions
# =============================================================================
ALLOWLIST_PATTERNS = [
    # Creating new branches is safe
    r"git\s+checkout\s+(-b|--orphan)\s+",
    # Unstaging files preserves work
    r"git\s+restore\s+--staged\s+",
    # Dry-run operations - but ONLY if -f/--force is NOT present
    r"git\s+clean\s+(?!.*(-f|--force)).*(-n|--dry-run)",
    # Deleting temp directories is fine
    r"rm\s+.*(/tmp/|/var/tmp/|\$TMPDIR/)",
    # Viewing permissions is safe
    r"chmod\s+--help",
    r"ls\s+-l",
]

# Pattern for rm flags: matches -r, -f, -R, -rf, --recursive, --force, --no-preserve-root
RM_FLAGS = r"(['\"]?-[rfR]+['\"]?|--recursive|--force|--no-preserve-root)\s+"

# =============================================================================
# ALWAYS BLOCKED - No way to proceed, even if intentional
# =============================================================================
BLOCK_PATTERNS = [
    # --no-preserve-root is ALWAYS dangerous
    (r"rm\s+.*--no-preserve-root",
     "rm --no-preserve-root explicitly bypasses safety checks"),

    # Catastrophic deletions - NEVER allow
    (rf"rm\s+({RM_FLAGS})*(/|/\*)\s*$",
     "rm on root directory - absolutely never allowed"),
    (rf"rm\s+({RM_FLAGS})*/(etc|usr|bin|sbin|boot|lib|lib64|sys|proc)\b",
     "rm on critical system directory"),

    # Raw disk writes
    (r"\bdd\s+.*of=/dev/[sh]d",
     "dd write to disk device"),
    (r"\bmkfs\b",
     "filesystem format command"),

    # Credential exfiltration attempts
    (r"curl.+(-d|--data).+[@<].*(\.env|credentials|\.aws|\.ssh)",
     "potential credential exfiltration via curl"),

    # Remote code execution - piping downloads to shell
    (r"curl\s+.*\|\s*(ba)?sh",
     "piping curl output to shell - remote code execution risk"),
    (r"wget\s+.*\|\s*(ba)?sh",
     "piping wget output to shell - remote code execution risk"),
    (r"curl\s+.*>\s*/tmp/.*&&.*sh\s+/tmp/",
     "download and execute pattern"),

    # Environment variable exfiltration
    (r"(env|printenv)\s*\|.*curl",
     "environment variable exfiltration via curl"),
    (r"(env|printenv)\s*\|.*wget",
     "environment variable exfiltration via wget"),
    (r"(env|printenv)\s*\|.*nc\b",
     "environment variable exfiltration via netcat"),
]

# =============================================================================
# ASK USER - Dangerous but sometimes legitimate
# =============================================================================
ASK_PATTERNS = [
    # Home directory operations
    (rf"rm\s+({RM_FLAGS})*(~|\$HOME)(/|\s|$)",
     "delete files in home directory"),

    # Shell config modifications (legitimate when user asks)
    (r">\s*~/?\.(bashrc|zshrc|profile|bash_profile|zprofile)",
     "overwrite shell config file"),

    # SSH config changes
    (r">\s*~/?\.ssh/(config|authorized_keys|known_hosts)",
     "modify SSH configuration"),

    # Git history rewriting - force push
    (r"git\s+push\s+.*(-f|--force)\b",
     "force push (rewrites remote history)"),

    # Git reset operations
    (r"git\s+reset\s+--hard",
     "hard reset (discards uncommitted changes)"),
    (r"git\s+reset\s+--merge",
     "merge reset (risks data loss)"),

    # Git checkout that discards changes
    (r"git\s+checkout\s+--\s+",
     "checkout -- (discards local changes)"),

    # Git restore that overwrites working tree
    (r"git\s+restore\s+(?!--staged)",
     "restore (permanent overwrites)"),

    # Git rebase
    (r"git\s+rebase\s+",
     "rebase (rewrites commit history)"),

    # Git clean (removes untracked files)
    (r"git\s+clean\s+.*-f",
     "clean -f (removes untracked files permanently)"),

    # Git branch force delete
    (r"git\s+branch\s+.*-D\b",
     "branch -D (force-deletes without merge check)"),

    # Git stash destruction
    (r"git\s+stash\s+(drop|clear)",
     "stash drop/clear (permanently deletes stashed changes)"),

    # Docker privileged operations
    (r"docker\s+run\s+.*--privileged",
     "run privileged container"),
    (r"docker\s+run\s+.*-v\s+/:/",
     "mount root filesystem in container"),

    # Mass process operations
    (r"pkill\s+.*-9",
     "force kill processes"),
    (r"killall\s+",
     "kill processes by name"),

    # Cron modifications
    (r"crontab\s+",
     "modify scheduled tasks"),

    # Package installation (can run arbitrary scripts)
    (r"(npm|yarn|pnpm)\s+install\s+(?!-)",
     "install npm packages (runs install scripts)"),
    (r"pip\s+install\s+(?!-e\s+\.)",
     "install pip packages"),

    # Indirect rm via xargs/find -exec
    (r"\|\s*xargs\s+.*\brm\b",
     "piped rm via xargs (indirect delete)"),
    (r"find\s+.*-exec\s+rm\b",
     "find -exec rm (indirect delete)"),

    # Overly permissive chmod
    (r"chmod\s+777\s+",
     "chmod 777 (world-writable)"),
    (r"chmod\s+666\s+",
     "chmod 666 (world-writable files)"),
    (r"chmod\s+-R\s+777\s+",
     "recursive chmod 777 (world-writable)"),
    (r"chmod\s+a\+w\s+",
     "chmod a+w (world-writable)"),

    # Ownership changes
    (r"chown\s+.*:",
     "change file ownership"),
    (r"chown\s+-R\s+",
     "recursive ownership change"),

    # Netcat - often used for reverse shells
    (r"\bnc\s+.*-e\s+",
     "netcat with command execution"),
    (r"\bnetcat\s+.*-e\s+",
     "netcat with command execution"),
    (r"\bnc\s+-l.*\|.*sh",
     "netcat listener piped to shell"),
]

# =============================================================================
# WARN ONLY - Log but allow
# =============================================================================
WARN_PATTERNS = [
    (rf"rm\s+{RM_FLAGS}",
     "recursive/force delete - verify path is intended"),
]

# Pre-compile all patterns at module load
COMPILED_ALLOWLIST = compile_allowlist(ALLOWLIST_PATTERNS)
COMPILED_BLOCK = compile_patterns(BLOCK_PATTERNS)
COMPILED_ASK = compile_patterns(ASK_PATTERNS)
COMPILED_WARN = compile_patterns(WARN_PATTERNS)


def check_command(command: str) -> tuple[str, str]:
    """
    Check command against patterns.
    Returns: (decision, message)
      decision: "block", "ask", "warn", or "allow"
    """
    # Normalize the command first
    command = normalize_command(command)

    # Load config for user extensions
    config = load_config()
    bash_config = config.get("bash_safety", {})

    # Check allowlist first - these bypass all restrictions
    if match_allowlist(command, COMPILED_ALLOWLIST):
        return "allow", ""

    # Check user-defined allowlist
    extra_allowlist = bash_config.get("extra_allowlist", [])
    if extra_allowlist:
        user_allowlist = compile_allowlist(extra_allowlist)
        if match_allowlist(command, user_allowlist):
            return "allow", ""

    # Check always-block (built-in + user-defined)
    matched, message = match_patterns(command, COMPILED_BLOCK)
    if matched:
        return "block", message

    extra_block = bash_config.get("extra_block_patterns", [])
    if extra_block:
        user_block = compile_patterns(extra_block)
        matched, message = match_patterns(command, user_block)
        if matched:
            return "block", message

    # Check ask patterns (built-in + user-defined)
    matched, message = match_patterns(command, COMPILED_ASK)
    if matched:
        return "ask", message

    extra_ask = bash_config.get("extra_ask_patterns", [])
    if extra_ask:
        user_ask = compile_patterns(extra_ask)
        matched, message = match_patterns(command, user_ask)
        if matched:
            return "ask", message

    # Check warn patterns
    matched, message = match_patterns(command, COMPILED_WARN)
    if matched:
        return "warn", message

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

    if decision == "block":
        output_block(message)
    elif decision == "ask":
        output_ask(f"Safety check: {message}")
    elif decision == "warn":
        output_warn(message)
    else:
        output_allow()


if __name__ == "__main__":
    main()
