---
name: devdocs
description: Session continuity for AI-assisted development using persistent documentation. Use when starting a new task, resuming work across sessions, or when context is getting high and state needs to be persisted to disk.
---

# DevDocs Pattern

## Overview

Maintain session continuity across AI-assisted development sessions by persisting working state to disk. This pattern prevents context loss from token limits and enables seamless handoffs between sessions.

**Superpowers Integration:** DevDocs integrates with the `superpowers` plugin workflow. When superpowers creates specs in `/docs/plans/`, devdocs adds progress tracking alongside them.

**Beads Integration:** DevDocs can integrate with Beads for task tracking. When Beads is available, devdocs can sync task status and detect parallel work across team members.

## When to Use

- Starting a new multi-session task or feature implementation
- Context usage is approaching 60-70% and state needs to be saved
- Resuming work on an existing task from a previous session
- Implementing a GitHub issue with detailed tracking needs
- Complex work requiring progress tracking and failed-approach logging
- **Executing a superpowers plan** that spans multiple sessions
- **Working with Beads task tracking** to coordinate with team members
- **Detecting parallel work** when multiple people work on the same codebase

## Superpowers Integration

DevDocs is designed to work seamlessly with the superpowers plugin workflow. Superpowers handles the "what" (specs and plans), while DevDocs handles the "when" (session continuity and progress tracking).

### Full Workflow Integration

| Superpowers Skill | When Used | Creates | DevDocs Role |
|-------------------|-----------|---------|--------------|
| `brainstorming` | Initial design exploration | `docs/plans/YYYY-MM-DD-<topic>-design.md` | References design spec in `progress.md` header |
| `writing-plans` | Implementation planning | `docs/plans/YYYY-MM-DD-<feature>.md` | References plan spec in `progress.md` header |
| `test-driven-development` | During implementation | TDD workflow in session | Tracks RED-GREEN-REFACTOR cycles in `progress.md` |
| `systematic-debugging` | When bugs occur | Debugging analysis | Logs root cause in "Failed Approaches" section |
| `verification-before-completion` | Before finishing | Verification checks | Triggers completion checklist |
| `requesting-code-review` | After verification | Code review request | Triggers archive workflow |
| `finishing-a-development-branch` | Final integration | Merge/PR decision | Completes devdocs lifecycle |

### Directory Structure

**Recommended structure with Superpowers:**
```
docs/plans/
├── 2026-01-31-user-auth-design.md      # superpowers:brainstorming
├── 2026-01-31-user-auth.md             # superpowers:writing-plans
├── user-auth/
│   └── progress.md                      # devdocs session tracking
└── archive/
    └── user-auth.md                     # devdocs completion summary
```

**Key Principles:**
1. Superpowers specs live in `docs/plans/` root (never delete these)
2. DevDocs creates `docs/plans/<feature>/progress.md` for session tracking
3. When complete, `docs/plans/archive/<feature>.md` stores the summary
4. The superpowers spec IS the plan — DevDocs never creates a separate `plan.md`

### When to Use DevDocs with Superpowers

```
┌─────────────────────────────────────────┐
│ Starting a new task?                    │
└────────────┬────────────────────────────┘
             │
    ┌────────▼───────────┐
    │ Single session?    │
    │ (< 2 hours)        │
    └─┬────────────────┬─┘
      │ YES            │ NO
      │                │
      ▼                ▼
  Superpowers only   Superpowers + DevDocs
  (no devdocs)       for continuity
      │                │
      │                ▼
      │            1. brainstorming
      │            2. writing-plans
      │            3. CREATE progress.md
      │            4. Track across sessions
      │            5. verification-before-completion
      │            6. Archive when done
      ▼
  brainstorming
  writing-plans
  test-driven
  verification
  (all in one session)
```

**Use DevDocs when:**
- Task will span multiple sessions (> 2 hours)
- Context usage approaching 60-70%
- Need to track failed approaches across sessions
- Multiple TDD/debugging cycles expected

**Skip DevDocs when:**
- Single session task (< 2 hours)
- Simple implementation from clear plan
- No session handoff needed

## Beads Integration

DevDocs can integrate with Beads for enhanced task tracking and team collaboration. Beads provides structured task state management and helps detect when multiple team members are working on overlapping tasks.

### Benefits

**Task State Synchronization:**
- Beads stores task status in `.beads/` directory (git-ignored)
- Updates sync with GitHub issues automatically
- Tracks task lifecycle: planning → in_progress → review → done

**Parallel Work Detection:**
- Detects when team members work on same files
- Provides warnings before potential merge conflicts
- Helps coordinate work distribution

**GitHub Integration:**
- Syncs task status with GitHub issue labels
- Updates issue comments with progress
- Links tasks to PRs automatically

### Workflow with Beads

When Beads is available, devdocs enhances the workflow:

```
1. superpowers:writing-plans      → Create plan in docs/plans/
2. beads task start <issue>       → Initialize task tracking
3. devdocs-create.sh <issue>      → Create progress.md
4. [Work on implementation]
5. beads task status              → Check for parallel work
6. beads task update              → Sync progress to GitHub
7. beads task complete            → Mark done, trigger review
8. archive-devdocs.sh <feature>   → Archive session history
```

### Beads Commands Integration

DevDocs templates include Beads command references:

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `beads task start <issue>` | Initialize task tracking | After creating devdocs |
| `beads task status` | Check current task state | Before starting work session |
| `beads task update` | Sync progress to GitHub | After completing a phase |
| `beads task complete` | Mark task done | Before archiving devdocs |
| `beads check` | Detect parallel work | Before pushing changes |

### When to Use Beads with DevDocs

**Use Beads when:**
- Working in a team environment with multiple developers
- Need to coordinate work on shared codebase
- Want automatic GitHub issue synchronization
- Need parallel work detection

**Skip Beads when:**
- Working solo on personal project
- GitHub integration not needed
- Simple task tracking in devdocs is sufficient

## Workflow

### Directory Structure Options

**Option 1: With Superpowers (Recommended)**
Use `docs/plans/` for tight integration with superpowers workflow:
```
docs/plans/
├── 2026-01-31-auth-design.md           # superpowers:brainstorming
├── 2026-01-31-auth.md                  # superpowers:writing-plans
├── auth/
│   └── progress.md                      # devdocs session tracking
└── archive/
    └── auth.md                          # devdocs completion summary
```

**Option 2: Standalone (No Superpowers)**
Use `.github/devdocs/` for projects without superpowers:
```
.github/devdocs/
├── issue-123-auth/
│   ├── plan.md                          # devdocs plan
│   └── progress.md                      # devdocs progress
└── archive/
    └── issue-123-auth.md                # devdocs completion
```

### 1. Start a new task

**With Superpowers spec (recommended):**
If a superpowers spec exists in `docs/plans/`, create only the progress file:
```bash
mkdir -p docs/plans/<feature-name>
# Create progress.md using the template, linking to the superpowers spec
```

**With GitHub Issue (and superpowers):**
```bash
# First run superpowers:brainstorming and superpowers:writing-plans
# Then create progress tracking:
mkdir -p docs/plans/<feature-name>
# Create progress.md with issue link and spec references
```

**Standalone task (no superpowers):**
```bash
# For projects not using superpowers
mkdir -p .github/devdocs/<task-name>
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

**With Superpowers (docs/plans/):**

| File | Created By | Purpose |
|------|------------|---------|
| `docs/plans/YYYY-MM-DD-<topic>-design.md` | superpowers:brainstorming | Design specification |
| `docs/plans/YYYY-MM-DD-<feature>.md` | superpowers:writing-plans | Implementation plan |
| `docs/plans/<feature>/progress.md` | devdocs | Session handoffs, current status, blockers, decisions |
| `docs/plans/archive/<feature>.md` | devdocs | Completed task summary with key learnings |
| `docs/plans/archive/INDEX.md` | devdocs | Searchable index of archived tasks |
| `skills/devdocs/DEBUGGING.md` | Manual | Common debugging patterns (update with discoveries) |

**Standalone (without Superpowers):**

| File | Purpose |
|------|---------|
| `.github/devdocs/<task>/plan.md` | Goals, phases, approach |
| `.github/devdocs/<task>/progress.md` | Session handoffs, current status |
| `.github/devdocs/archive/<task>.md` | Completed task summary |
| `.github/devdocs/archive/INDEX.md` | Searchable index |

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
# Check if project uses superpowers
ls docs/plans/*.md 2>/dev/null

# Also check for docs/plans/ directory existence
[ -d "docs/plans" ] && echo "Superpowers structure detected"
```

**If superpowers specs exist** (files like `YYYY-MM-DD-<feature>-design.md` or `YYYY-MM-DD-<feature>.md`):
1. ✅ Use `docs/plans/` as the base directory
2. ✅ **Do NOT create a separate plan.md** — the superpowers spec IS the plan
3. ✅ Create only `docs/plans/<feature>/progress.md` for session tracking
4. ✅ Link to superpowers spec(s) in the progress file header
5. ✅ Create archive in `docs/plans/archive/`

**If no superpowers** (no `docs/plans/` directory or no dated spec files):
1. ✅ Use `.github/devdocs/` as the base directory
2. ✅ Create both `plan.md` and `progress.md`
3. ✅ Create archive in `.github/devdocs/archive/`

### Creating DevDocs

**Path 1: With Superpowers (Recommended)**
```bash
# Step 1: User runs superpowers:brainstorming
# Creates: docs/plans/YYYY-MM-DD-<feature>-design.md

# Step 2: User runs superpowers:writing-plans
# Creates: docs/plans/YYYY-MM-DD-<feature>.md

# Step 3: Create DevDocs progress tracking
# Extract feature name from spec filename (e.g., 2026-01-31-user-auth.md → user-auth)
FEATURE_NAME="user-auth"  # from superpowers spec
mkdir -p docs/plans/$FEATURE_NAME

# Create progress.md with references to superpowers specs
# Use progress.template.md and fill in:
# - Link to design spec (if exists)
# - Link to plan spec
# - GitHub issue link (if applicable)
```

**Path 2: With GitHub Issue + Superpowers**
```bash
# Assumes superpowers specs already created
./scripts/devdocs-create.sh <issue-number>
# Auto-detects superpowers specs and creates in docs/plans/
```

**Path 3: Standalone (No Superpowers)**
```bash
# For projects not using superpowers
mkdir -p .github/devdocs/<task-name>
# Create BOTH plan.md AND progress.md using templates
```

### Progress File for Superpowers Integration

When creating `progress.md` alongside superpowers specs, use this header:

```markdown
# <Feature Name> - Progress

**Superpowers Design:** [YYYY-MM-DD-<feature>-design.md](../YYYY-MM-DD-<feature>-design.md) (if exists)
**Superpowers Plan:** [YYYY-MM-DD-<feature>.md](../YYYY-MM-DD-<feature>.md)
**GitHub Issue:** #[number] or N/A
**Last Updated:** [YYYY-MM-DD]
**Current Phase:** [Phase X - Name from superpowers plan]
**Overall Status:** 🟡 In Progress

---

## Session Handoff (TL;DR)
| Field | Value |
|-------|-------|
| **Next Action** | [Specific next step] |
| **Context Needed** | [Files to read] |
| **Blocker** | None / [Description] |
| **Current Superpowers Skill** | test-driven-development / systematic-debugging / etc. |

---

## Superpowers Workflow Tracking

**Completed:**
- [x] brainstorming (design spec created)
- [x] writing-plans (implementation plan created)

**In Progress:**
- [ ] test-driven-development (RED-GREEN-REFACTOR cycles below)
- [ ] systematic-debugging (if needed)

**Next:**
- [ ] verification-before-completion
- [ ] requesting-code-review
- [ ] finishing-a-development-branch

---

## TDD Cycle Tracking (if using test-driven-development)

| Cycle | Feature | RED | GREEN | REFACTOR | Notes |
|-------|---------|-----|-------|----------|-------|
| 1 | [feature] | ✅ | ✅ | ✅ | [notes] |
| 2 | [feature] | ✅ | 🟡 | ⬜ | Currently here |

---

## Debugging Log (if using systematic-debugging)

**Latest Debugging Session:** [Date]
- **Root Cause:** [from 4-phase analysis]
- **Fix Applied:** [description]
- **Verification:** [how confirmed]
- **Added to Failed Approaches:** [Yes/No]

...
```

### Archiving Completed Tasks

**With Superpowers (Recommended):**
```bash
# After running superpowers:verification-before-completion
# and superpowers:requesting-code-review
./scripts/archive-devdocs.sh <feature-name>

# This creates:
# - docs/plans/archive/<feature-name>.md (summary)
# - Updates docs/plans/archive/INDEX.md
# - Deletes docs/plans/<feature-name>/ (progress tracking)
# - KEEPS superpowers specs in docs/plans/*.md (never delete these!)
```

**Standalone (No Superpowers):**
```bash
./scripts/archive-devdocs.sh <task-name>

# This creates:
# - .github/devdocs/archive/<task-name>.md
# - Updates .github/devdocs/archive/INDEX.md
# - Optionally deletes .github/devdocs/<task-name>/
```

**What Gets Archived vs Kept:**

| File | Action | Reason |
|------|--------|--------|
| `docs/plans/YYYY-MM-DD-*.md` | ✅ KEEP | Superpowers specs are permanent |
| `docs/plans/<feature>/progress.md` | ❌ DELETE | Session tracking no longer needed |
| `docs/plans/archive/<feature>.md` | ✅ CREATE | Permanent summary with learnings |
| `docs/plans/archive/INDEX.md` | ✅ UPDATE | Add searchable entry |

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

### Beads Integration Workflows

**Detecting Beads Availability:**
```bash
# Check if Beads is installed and configured
command -v beads >/dev/null 2>&1 && echo "Beads available"

# Check if current project uses Beads
[ -f ".beads/config.json" ] && echo "Beads configured for project"
```

**Starting Work with Beads:**
```bash
# After creating devdocs, initialize Beads tracking
beads task start <issue-number>

# This creates:
# - .beads/tasks/<issue-number>.json (task state)
# - Links to GitHub issue
# - Sets status to "in_progress"
```

**Checking for Parallel Work:**
```bash
# Before starting a work session, check for conflicts
beads check

# Example output:
# Warning: User @alice is working on src/feature.py (issue #123)
# Your task #124 also modifies this file
# Consider coordinating before proceeding
```

**Syncing Progress to GitHub:**
```bash
# After completing a phase in progress.md
beads task update

# This:
# - Reads current phase from progress.md
# - Updates GitHub issue with comment
# - Syncs task status to .beads/
```

**Completing Work with Beads:**
```bash
# Before archiving devdocs
beads task complete

# This:
# - Sets task status to "done"
# - Adds completion comment to GitHub issue
# - Updates .beads/tasks/<issue>.json
# - Optionally creates PR if configured
```

**Agent Instructions for Beads:**

When Beads is available, agents should:

1. **On task start:**
   - Run `beads task start <issue>` after creating devdocs
   - Include Beads status in progress.md header

2. **During work:**
   - Run `beads check` before modifying files to detect parallel work
   - If parallel work detected, inform user and suggest coordination
   - Update Beads status when completing phases

3. **On session handoff:**
   - Run `beads task update` to sync progress to GitHub
   - Include Beads status in handoff notes

4. **On completion:**
   - Run `beads task complete` before archiving
   - Verify GitHub issue updated correctly

**Integration with Templates:**

The progress.template.md includes Beads integration fields:

```markdown
## Beads Status (if using Beads)

| Field | Value |
|-------|-------|
| **Task ID** | #<issue-number> |
| **Status** | in_progress / review / done |
| **Last Sync** | YYYY-MM-DD HH:MM |
| **Parallel Work** | None / @user on file.py |

**Beads Commands:**
- Start: `beads task start <issue>`
- Status: `beads task status`
- Update: `beads task update`
- Complete: `beads task complete`
- Check: `beads check`
```

## Reference Material

- See [README.md](README.md) for complete methodology documentation
- See [DEBUGGING.md](DEBUGGING.md) for debugging patterns
- See [templates/](templates/) for plan and progress templates
- See [feature/](feature/) for feature documentation templates
