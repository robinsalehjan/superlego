#!/usr/bin/env python3
"""
PreToolUse hook for Write/Edit tools.
Protects sensitive file paths from modification.

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
    compile_patterns,
    match_patterns,
    normalize_path,
    load_config,
)

# =============================================================================
# ALWAYS BLOCKED - Never allow writing to these
# =============================================================================
BLOCK_PATTERNS = [
    # System directories
    (r"^/(etc|usr|bin|sbin|boot|lib|lib64|sys|proc)(/|$)",
     "system directory"),
    (r"^/var/(log|run|lock)(/|$)",
     "system runtime directory"),
]

# =============================================================================
# ASK USER - Sensitive but sometimes legitimate
# =============================================================================
ASK_PATTERNS = [
    # Shell configs
    (r"/\.(bashrc|zshrc|profile|bash_profile|zprofile)$",
     "shell configuration file"),

    # SSH
    (r"/\.ssh/",
     "SSH configuration"),

    # Git config
    (r"/\.gitconfig$",
     "global git configuration"),

    # AWS/Cloud credentials
    (r"/\.(aws|gcp|azure)/",
     "cloud credentials"),

    # Environment files with secrets
    (r"\.env$",
     ".env file (may contain secrets)"),
    (r"\.env\.(local|prod|production)$",
     "environment file (may contain secrets)"),

    # Claude config (prevent self-modification attacks)
    (r"/\.claude/.*-hook\.py$",
     "Claude safety hook"),
    (r"/\.claude/settings\.json$",
     "Claude settings"),

    # NPM/Yarn credentials
    (r"/\.npmrc$",
     ".npmrc (may contain auth tokens)"),
    (r"/\.yarnrc$",
     ".yarnrc (may contain auth tokens)"),
    (r"/\.yarnrc\.yml$",
     ".yarnrc.yml (may contain auth tokens)"),

    # Docker credentials
    (r"/\.docker/config\.json$",
     "Docker config (contains registry auth)"),

    # Network credentials
    (r"/\.netrc$",
     ".netrc (contains network credentials)"),

    # Private keys
    (r"\.pem$",
     "PEM file (may be private key)"),
    (r"\.key$",
     "KEY file (may be private key)"),
    (r"/id_rsa$",
     "RSA private key"),
    (r"/id_ed25519$",
     "Ed25519 private key"),
    (r"/id_ecdsa$",
     "ECDSA private key"),
    (r"/id_dsa$",
     "DSA private key"),

    # Kubernetes
    (r"/\.kube/config$",
     "Kubernetes config (contains cluster credentials)"),
    (r"/kubeconfig$",
     "Kubernetes config file"),

    # Database configs
    (r"/\.pgpass$",
     "PostgreSQL password file"),
    (r"/\.my\.cnf$",
     "MySQL config (may contain credentials)"),
]

# Pre-compile all patterns at module load
COMPILED_BLOCK = compile_patterns(BLOCK_PATTERNS)
COMPILED_ASK = compile_patterns(ASK_PATTERNS)


def check_path(file_path: str) -> tuple[str, str]:
    """
    Check if path is sensitive.
    Returns: (decision, message)
    """
    # Normalize path for consistent matching
    path = normalize_path(file_path)

    # Load config for user extensions
    config = load_config()
    file_config = config.get("file_safety", {})

    # Check always-block (built-in + user-defined)
    matched, message = match_patterns(path, COMPILED_BLOCK)
    if matched:
        return "block", message

    extra_block = file_config.get("extra_block_patterns", [])
    if extra_block:
        user_block = compile_patterns(extra_block)
        matched, message = match_patterns(path, user_block)
        if matched:
            return "block", message

    # Check ask patterns (built-in + user-defined)
    matched, message = match_patterns(path, COMPILED_ASK)
    if matched:
        return "ask", message

    extra_ask = file_config.get("extra_ask_patterns", [])
    if extra_ask:
        user_ask = compile_patterns(extra_ask)
        matched, message = match_patterns(path, user_ask)
        if matched:
            return "ask", message

    return "allow", ""


def main():
    hook_input = parse_input()
    if not hook_input:
        output_allow()

    if hook_input.tool_name not in ("Write", "Edit"):
        output_allow()

    file_path = hook_input.tool_input.get("file_path", "")
    if not file_path:
        output_allow()

    decision, message = check_path(file_path)

    if decision == "block":
        output_block(f"Cannot write to {message}")
    elif decision == "ask":
        output_ask(f"Safety check: modifying {message}")
    else:
        output_allow()


if __name__ == "__main__":
    main()
