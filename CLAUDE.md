# Superlego Plugin Development

Claude Code plugin for Swift/SwiftUI/iOS/macOS development skills.

## Quick Start

### Local Installation

Test the plugin locally:

```bash
# Main plugin
/plugin install /Users/robin.saleh-jan@m10s.io/Repositories/rokuru/superlego

# Safety hooks (optional)
/plugin install /Users/robin.saleh-jan@m10s.io/Repositories/rokuru/superlego/plugins/safety-hooks
```

### Reload After Changes

```bash
/plugin reload skills
```

## Skill Structure

Each skill must follow this structure:

```
skills/<skill-name>/
├── SKILL.md              # Required: Main skill file
├── references/           # Optional: Supporting docs
│   └── *.md
└── scripts/              # Optional: Helper scripts
```

### SKILL.md Requirements

**YAML Frontmatter** (required):
```yaml
---
name: skill-name
description: Brief description. Use when [trigger condition].
---
```

**Critical**:
- Frontmatter must be valid YAML
- `name` must match directory name
- `description` should include "Use when" trigger
- Invalid frontmatter = skill won't load

## Testing Skills

### 1. Verify Skill Loads

```bash
/help
# Check that your skill appears in the list
```

### 2. Test Invocation

```
Use the <skill-name> skill to test...
```

### 3. Validate References

Skills with `references/` should be readable:
```
Read the references in the <skill-name> skill directory
```

## Project Structure

```
.claude-plugin/          # Plugin manifests (plugin.json, marketplace.json)
skills/                  # Auto-discovered skills (directory name = skill name)
plugins/safety-hooks/    # Sub-plugin for bash command protection
docs/plans/              # Planning documents
.beads/                  # Issue tracking (beads task graph)
```

## Key Gotchas

1. **Plugin name mismatch**: `.claude-plugin/plugin.json` name ("skills") must match installation
2. **Invalid frontmatter**: Malformed YAML breaks skill loading silently
3. **Reload required**: Changes don't take effect until `/plugin reload skills`
4. **Directory naming**: Skill directory name must match frontmatter `name` field
5. **Marketplace structure**: `marketplace.json` lists both "skills" and "safety-hooks" plugins

## Development Workflow

1. Create skill directory under `skills/`
2. Write `SKILL.md` with valid frontmatter
3. Add `references/` if needed
4. Test locally: `/plugin install /path/to/superlego`
5. Verify: `/help` shows skill
6. Test invocation with skill
7. Commit when validated

## Integration with Superpowers

Superlego is designed to work alongside the [superpowers](https://github.com/obra/superpowers) plugin:
- `devdocs` skill creates progress tracking
- Complements superpowers' brainstorming/planning workflows
