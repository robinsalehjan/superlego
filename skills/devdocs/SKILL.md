---
name: devdocs
description: Session continuity for AI-assisted development using persistent documentation. Use when starting a new task, resuming work across sessions, or when context is getting high and state needs to be persisted to disk.
---

# DevDocs Pattern

## Overview

Maintain session continuity across AI-assisted development sessions by persisting working state to disk. This pattern prevents context loss from token limits and enables seamless handoffs between sessions.

**Superpowers Integration:** DevDocs integrates with the `superpowers` plugin workflow. When superpowers creates specs in `/docs/plans/`, devdocs adds progress tracking alongside them.

## When to Use

- Starting a new multi-session task or feature implementation
- Context usage is approaching 60-70% and state needs to be saved
- Resuming work on an existing task from a previous session
- Implementing a GitHub issue with detailed tracking needs
- Complex work requiring progress tracking and failed-approach logging
- **Executing a superpowers plan** that spans multiple sessions

## Superpowers Integration

When using the `superpowers` plugin, specs and plans are created in `/docs/plans/`:

| Superpowers Skill | Creates | DevDocs Adds |
|-------------------|---------|--------------|
| `superpowers:brainstorming` | `docs/plans/YYYY-MM-DD-<topic>-design.md` | `docs/plans/<topic>/progress.md` |
| `superpowers:writing-plans` | `docs/plans/YYYY-MM-DD-<feature>.md` | `docs/plans/<feature>/progress.md` |

**Workflow with Superpowers:**
1. Superpowers creates the design or implementation plan in `/docs/plans/`
2. DevDocs creates a matching directory with `progress.md` for session tracking
3. The superpowers spec becomes the "plan" — no need for a separate `plan.md`

**Example structure:**
```
docs/plans/
├── 2026-01-31-user-auth-design.md      # Created by superpowers:brainstorming
├── 2026-01-31-user-auth.md             # Created by superpowers:writing-plans
└── user-auth/
    └── progress.md                      # Created by devdocs for session tracking
```

## Workflow

### 1. Start a new task

**With Superpowers spec (recommended):**
If a superpowers spec exists in `/docs/plans/`, create only the progress file:
```bash
mkdir -p docs/plans/<feature-name>
# Create progress.md using the template, linking to the superpowers spec
```

**With GitHub Issue:**
```bash
./scripts/devdocs-create.sh <issue-number>
```

**Standalone task (no superpowers):**
```bash
mkdir -p docs/plans/<task-name>
# Create plan.md and progress.md using templates
```

### 2. Track progress during work

Update `progress.md` as work proceeds:
- Check off completed items
- Note current position with `← Currently here`
- Log failed approaches to prevent repeating mistakes
- Record decisions with rationale

### 3. End session at ~60-70% context

Before ending a session:
1. Update `progress.md` with current state
2. Fill in the **Session Handoff** table at the top
3. Note blockers and next steps
4. Commit changes

### 4. Resume in new session

Tell the agent:
```
Continue work on <feature-name>. Read docs/plans/<feature-name>/progress.md for current state.
```

### 5. Complete and archive

When finished:
```bash
./scripts/archive-devdocs.sh <task-name>
```

This creates a permanent summary in `docs/plans/archive/` and updates the index.

## Key Files

| File | Purpose |
|------|---------|
| `docs/plans/*.md` | Superpowers design specs and implementation plans |
| `docs/plans/<feature>/progress.md` | Session handoffs, current status, blockers, decisions |
| `docs/plans/archive/` | Completed task summaries and searchable index |
| `DEBUGGING.md` | Common debugging patterns (update with new discoveries) |

## Context Management

| Context Level | Action |
|---------------|--------|
| Below 50% | Optimal - continue working |
| 50-70% | Plan session handoff after current phase |
| 70-80% | Finish current task, persist state immediately |
| Above 80% | Stop immediately, save state to avoid auto-compaction |

## Session Handoff Template

Update the Session Handoff table in `progress.md`:

| Field | Value |
|-------|-------|
| **Next Action** | Specific next step with file/line reference |
| **Context Needed** | Files to read when resuming |
| **Blocker** | None or description |
| **Failed Approaches** | What was tried and didn't work |

## Agent Instructions

When operating in environments with terminal access (VS Code Copilot Chat, Claude Code CLI), execute scripts directly rather than manually creating files.

### Detecting Superpowers Integration

**Before creating devdocs, check for existing superpowers specs:**
```bash
ls docs/plans/*.md 2>/dev/null
```

If superpowers specs exist (files like `YYYY-MM-DD-<feature>-design.md` or `YYYY-MM-DD-<feature>.md`):
1. **Do NOT create a separate plan.md** — the superpowers spec IS the plan
2. Create only `docs/plans/<feature>/progress.md` for session tracking
3. Link to the superpowers spec in the progress file's header

### Creating DevDocs

**With existing superpowers spec (preferred):**
```bash
# Extract feature name from superpowers spec filename
# e.g., 2026-01-31-user-auth.md → user-auth
mkdir -p docs/plans/<feature-name>
# Create progress.md with reference to superpowers spec
```

**With GitHub Issue (if scripts installed):**
```bash
# Run in terminal - creates issue-linked devdocs with bidirectional GitHub linking
./scripts/devdocs-create.sh <issue-number>
```

**Standalone (no superpowers, no issue):**
```bash
mkdir -p docs/plans/<task-name>
# Create plan.md AND progress.md using templates
```

### Progress File for Superpowers Integration

When creating `progress.md` alongside a superpowers spec, use this header:

```markdown
# <Feature Name> - Progress

**Superpowers Spec:** [YYYY-MM-DD-<feature>.md](../YYYY-MM-DD-<feature>.md)
**GitHub Issue:** #[number] or N/A
**Last Updated:** [YYYY-MM-DD]
**Current Phase:** [Phase X - Name]
**Overall Status:** 🟡 In Progress

---

## Session Handoff (TL;DR)
...
```

### Archiving Completed Tasks

**If scripts are installed:**
```bash
./scripts/archive-devdocs.sh <task-name>
```

**Manual archiving:**
1. Create summary in `docs/plans/archive/<task-name>.md`
2. Add entry to `docs/plans/archive/INDEX.md`
3. Optionally delete the working devdocs directory (keep superpowers specs)

### Environment Compatibility

| Environment | Script Execution | Fallback |
|-------------|------------------|----------|
| VS Code Copilot Chat | ✅ Use `run_in_terminal` | Create files directly |
| Claude Code CLI | ✅ Use Bash tool | Create files directly |
| Claude Desktop | ❌ No terminal access | Create files directly |

### Installing Scripts to a Project

To enable script automation in a project, copy the scripts to the project root:
```bash
mkdir -p scripts
cp path/to/superlego/skills/devdocs/archive/scripts/*.sh scripts/
chmod +x scripts/*.sh
```

This standardizes script location at `./scripts/` for use across all skills.

## Reference Material

- See [README.md](README.md) for complete methodology documentation
- See [DEBUGGING.md](DEBUGGING.md) for debugging patterns
- See [templates/](templates/) for plan and progress templates
- See [feature/](feature/) for feature documentation templates
