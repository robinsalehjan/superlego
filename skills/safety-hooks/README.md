# Safety Hooks v2.0.0

A Claude Code plugin that prevents dangerous operations before they happen—even when running with `--dangerously-skip-permissions`.

## Quick Start

```bash
# Add the marketplace
/plugin marketplace add /path/to/superlego

# Install the plugin
/plugin install safety-hooks@superlego

# Restart Claude Code
```

## How It Works

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│ Claude attempts │────▶│ Safety Hook  │────▶│ Decision        │
│ Bash/Write/Edit │     │ intercepts   │     │                 │
└─────────────────┘     └──────────────┘     │ • Block (exit 2)│
                                             │ • Ask user      │
                                             │ • Warn + allow  │
                                             │ • Allow         │
                                             └─────────────────┘
```

Hooks check commands against patterns in order: **allowlist → block → ask → warn → allow**

## Protection Levels

| Level | Action | When |
|-------|--------|------|
| **Block** | Stops execution, shows error | Catastrophic operations |
| **Ask** | Prompts user for confirmation | Dangerous but sometimes needed |
| **Warn** | Logs warning, allows execution | Potentially risky |
| **Allow** | Silent pass-through | Safe operations |

## What's Protected

### Bash Commands

| Blocked | Ask Confirmation |
|---------|------------------|
| `rm -rf /` | `rm -rf ~/` |
| `rm -rf /etc`, `/usr`, `/bin` | `git push --force` |
| `dd of=/dev/sda` | `git reset --hard` |
| `mkfs.*` | `git rebase` |
| `curl ... \| bash` | `git clean -f` |
| `wget ... \| sh` | `chmod 777` |
| `curl -d @.env` (exfiltration) | `chown` |
| `env \| curl` (exfiltration) | `npm/pip install` |
| | `docker run --privileged` |
| | `nc -e` (netcat exec) |

### File Writes

| Blocked | Ask Confirmation |
|---------|------------------|
| `/etc/*` | `.bashrc`, `.zshrc` |
| `/usr/*`, `/bin/*` | `~/.ssh/*` |
| `/var/log/*` | `.aws/`, `.gcp/`, `.azure/` |
| | `.env`, `.env.production` |
| | `.npmrc`, `.yarnrc` |
| | `.docker/config.json` |
| | `*.pem`, `*.key`, `id_rsa` |
| | `.kube/config` |
| | `.pgpass`, `.my.cnf` |
| | `~/.claude/settings.json` |

### Git Operations

| Ask Confirmation |
|------------------|
| Commit to `main`/`master` |
| Push to protected branches |
| Merge into protected branches |
| `gh pr merge` |
| Delete release tags (`v*`, `release-*`) |

## Configuration

Edit `hooks/config.json` to customize behavior:

```json
{
  "git_protection": {
    "protected_branches": ["main", "master", "production"],
    "protected_tag_prefixes": ["v", "release-"],
    "ask_on_merge_to_protected": true,
    "ask_on_tag_delete": true
  },

  "bash_safety": {
    "extra_allowlist": ["rm -rf ./node_modules"],
    "extra_block_patterns": [],
    "extra_ask_patterns": [
      ["terraform\\s+destroy", "Terraform destroy"],
      ["kubectl\\s+delete", "Kubernetes delete"]
    ]
  },

  "file_safety": {
    "extra_block_patterns": [],
    "extra_ask_patterns": [
      ["/my/sensitive/path", "sensitive file"]
    ]
  }
}
```

### Pattern Syntax

Patterns use Python regex. Special characters need escaping:

```json
"extra_ask_patterns": [
  ["terraform\\s+destroy", "Terraform destroy command"],
  ["DROP\\s+TABLE", "SQL DROP TABLE"]
]
```

### Allowlist

Bypass all checks for specific patterns:

```json
"extra_allowlist": [
  "rm -rf ./dist",
  "rm -rf ./build"
]
```

## Files

```
safety-hooks/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── hooks/
│   ├── hooks.json            # Hook registration
│   ├── hook_utils.py         # Shared utilities
│   ├── config.json           # User configuration
│   ├── bash-safety-hook.py   # Bash protection
│   ├── file-safety-hook.py   # File write protection
│   └── git-branch-protection-hook.py
└── tests/
    └── test_hooks.py         # 119 tests
```

## Testing

```bash
# Run all tests
cd skills/safety-hooks
python3 tests/test_hooks.py

# Or with pytest
pytest tests/test_hooks.py -v
```

## Limitations

- Adds ~5ms latency per command (subprocess overhead)
- Regex-based; complex shell escaping may bypass checks
- Git branch detection requires being in a git repository
- Cannot prevent execution of compiled binaries or obfuscated commands

## Adding New Patterns

1. Identify the pattern to protect against
2. Add to `BLOCK_PATTERNS` or `ASK_PATTERNS` in the appropriate hook
3. Add tests in `tests/test_hooks.py`
4. Run tests: `python3 tests/test_hooks.py`

## License

MIT License - see [LICENSE](LICENSE) file for details.
