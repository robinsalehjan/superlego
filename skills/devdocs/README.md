# DevDocs Pattern

This directory implements the **DevDocs Pattern** for session continuity across AI-assisted development sessions, with **tight superpowers integration** (recommended) or standalone operation.

## Prerequisites

**Required:**
- Git (for version control)
- GitHub CLI (`gh`) installed and authenticated for GitHub integration

**Optional:**
- Superpowers plugin (recommended for planning workflows)
- Beads task tracker (for team coordination and parallel work detection)
- `jq` (for JSON processing in scripts)

## Superpowers Integration (Recommended)

DevDocs is designed to work seamlessly with the **superpowers** plugin workflow. Superpowers handles the "what" (specs/plans), while DevDocs handles the "when" (session continuity).

**Directory Structure with Superpowers:**
```
docs/plans/
├── 2026-01-31-user-auth-design.md      # superpowers:brainstorming
├── 2026-01-31-user-auth.md             # superpowers:writing-plans
├── user-auth/
│   └── progress.md                      # devdocs session tracking (TDD, debugging, handoffs)
└── archive/
    └── user-auth.md                     # devdocs completion summary
    └── INDEX.md                         # searchable archive index
```

**Standalone (No Superpowers):**
```
.github/devdocs/
├── issue-123-feature/
│   ├── plan.md                          # devdocs plan (replaces superpowers specs)
│   └── progress.md                      # devdocs progress
└── archive/
    └── issue-123-feature.md
    └── INDEX.md
```

**Key Principle:** When superpowers specs exist, devdocs does NOT create `plan.md` — the superpowers spec IS the plan. The script auto-detects which mode to use.

## Architecture

DevDocs uses a three-layer architecture to manage task state, planning, and execution:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Layer 1: Planning                             │
│                   (What to build)                                │
├─────────────────────────────────────────────────────────────────┤
│  Superpowers Plugin (Optional)                                   │
│  - brainstorming     → docs/plans/YYYY-MM-DD-feature-design.md  │
│  - writing-plans     → docs/plans/YYYY-MM-DD-feature.md         │
│                                                                  │
│  OR Manual Planning                                              │
│  - .github/devdocs/<task>/plan.md                               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                 Layer 2: Execution Tracking                      │
│              (How work progresses)                               │
├─────────────────────────────────────────────────────────────────┤
│  DevDocs Progress Files                                          │
│  - docs/plans/<feature>/progress.md (with superpowers)          │
│  - .github/devdocs/<task>/progress.md (standalone)              │
│                                                                  │
│  Tracks:                                                         │
│  - Current phase and task status                                │
│  - Session handoffs (context for next session)                  │
│  - Failed approaches (what didn't work)                         │
│  - Blockers and decisions                                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                Layer 3: Task State (Optional)                    │
│            (Team coordination)                                   │
├─────────────────────────────────────────────────────────────────┤
│  Beads Task Tracker (Optional)                                   │
│  - .beads/tasks/<issue>.json (local state, git-ignored)         │
│  - GitHub issue integration (syncs status)                      │
│  - Parallel work detection                                      │
│                                                                  │
│  When to use:                                                    │
│  - Team environment with multiple developers                    │
│  - Need coordination on shared codebase                         │
│  - Want automatic GitHub sync                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Workflow Phases

**Phase 1: Planning**
- Create specs using superpowers (recommended) or manual planning
- Define goals, phases, and success criteria
- Creates plan files in `docs/plans/` or `.github/devdocs/`

**Phase 2: Execution**
- Initialize progress tracking with `devdocs-create.sh`
- Work through implementation phases
- Update `progress.md` with current state, blockers, decisions
- Use session handoffs at 60-70% context
- Optional: Track with Beads for team coordination

**Phase 3: Completion**
- Run verification and code review (superpowers skills)
- Archive session history with `archive-devdocs.sh`
- Creates permanent summary in archive/
- Updates archive INDEX for searchability

## Beads Integration (Optional)

Beads adds structured task tracking with dependency management and GitHub sync to the DevDocs workflow. Use it for team coordination and parallel work detection.

### What Changed

The Beads integration adds:

**New Scripts (5):**
- `bd-init.sh` - Initialize Beads epic from plan
- `bd-from-plan.sh` - Extract structured tasks from plan
- `bd-sync-to-github.sh` - Sync Beads status to GitHub
- `bd-parallel-tasks.sh` - Find ready tasks for parallel work
- `bd-cleanup.sh` - Archive completed epic

**Enhanced Scripts (2):**
- `devdocs-create.sh` - Added `--beads` flag to auto-initialize epic
- `archive-devdocs.sh` - Auto-detects and archives Beads epic

**Updated Templates (1):**
- `progress.template.md` - Added Beads integration sections

**Updated Documentation (4):**
- `SKILL.md` - Added comprehensive Beads integration section
- `README.md` - Added three-layer architecture diagram
- `.gitignore` - Added `.beads/` directory
- `TESTING.md` - Added Beads test scenarios

### Installation

**Prerequisites:**
- Git repository (required)
- GitHub CLI (`gh`) installed and authenticated (required)
- Bash shell (required)
- Beads task tracker installed (optional, for enhanced features)
- `jq` for JSON processing (optional, used by Beads scripts)

**Setup Steps:**

1. **Copy scripts to your project:**
   ```bash
   mkdir -p scripts
   cp skills/devdocs/scripts/*.sh scripts/
   chmod +x scripts/*.sh
   ```

2. **Copy templates:**
   ```bash
   mkdir -p .github/devdocs/templates
   cp skills/devdocs/templates/* .github/devdocs/templates/
   ```

   Or for superpowers integration:
   ```bash
   mkdir -p docs/plans/templates
   cp skills/devdocs/templates/* docs/plans/templates/
   ```

3. **Install Beads (optional):**
   ```bash
   # Installation method depends on Beads distribution
   # Example: npm install -g @beads/cli
   beads init
   ```

4. **Verify setup:**
   ```bash
   # Check scripts are executable
   ls -la scripts/bd-*.sh

   # Check Beads available (if installed)
   command -v bd && echo "Beads available"
   ```

### Usage Examples

**Basic Workflow (Without Beads):**
```bash
# Create devdocs for GitHub issue
./scripts/devdocs-create.sh 123

# Work on implementation, update progress.md

# Archive when complete
./scripts/archive-devdocs.sh issue-123-feature-name
```

**Enhanced Workflow (With Beads):**
```bash
# Create devdocs with Beads epic
./scripts/devdocs-create.sh 123 --beads

# Check what you created
cat docs/plans/feature/progress.md
# Shows: Beads Epic: bd-xxxx with task table

# Find tasks ready for parallel work
./scripts/bd-parallel-tasks.sh bd-xxxx

# Update a task status in Beads (external to DevDocs)
bd complete bd-c3d4

# Sync status back to GitHub
./scripts/bd-sync-to-github.sh 123 bd-xxxx

# Archive with Beads stats
./scripts/archive-devdocs.sh issue-123-feature-name
# Archive includes: "Beads Task Tracking" section with completion stats
```

**Script-by-Script Examples:**

**bd-init.sh** - Initialize epic from devdocs:
```bash
./scripts/bd-init.sh issue-123-feature

# Output:
# {
#   "epic_id": "bd-a1b2",
#   "total_tasks": 8,
#   "created_tasks": 8
# }
```

**bd-from-plan.sh** - Extract tasks from plan:
```bash
./scripts/bd-from-plan.sh docs/plans/feature/plan.md

# Output (JSON):
# {
#   "phases": [
#     {
#       "name": "Phase 1: Setup",
#       "tasks": [
#         {"title": "Create data models", "estimate": "1h", "deps": []},
#         {"title": "Add unit tests", "estimate": "2h", "deps": ["bd-c3d4"]}
#       ]
#     }
#   ]
# }
```

**bd-sync-to-github.sh** - Sync epic status to issue:
```bash
./scripts/bd-sync-to-github.sh 123 bd-a1b2

# Posts GitHub comment:
# "Epic Progress: 6/8 tasks complete (75%)
#  See devdocs for details: docs/plans/feature/"
```

**bd-parallel-tasks.sh** - Find ready tasks:
```bash
./scripts/bd-parallel-tasks.sh bd-a1b2

# Output:
# bd-e5f6: Implement batch upload (no blockers)
# bd-g7h8: Add integration tests (no blockers)
```

**bd-cleanup.sh** - Archive epic and get stats:
```bash
./scripts/bd-cleanup.sh bd-a1b2

# Output (JSON):
# {
#   "epic_id": "bd-a1b2",
#   "total": 8,
#   "completed": 8,
#   "completion_rate": 100.0,
#   "archived_at": "2026-02-04T10:30:00Z"
# }
```

### Benefits

**Structured Task Tracking:**
- Before: Manual task lists in progress.md, no task state persistence
- After: Structured task state in `.beads/` (git-ignored), task dependencies enforced

**Team Coordination:**
- Before: No visibility into what others are working on, potential merge conflicts discovered late
- After: Parallel work detection warns of conflicts, team members see current task status

**GitHub Integration:**
- Before: Manual issue updates, no automatic progress reporting
- After: Automatic issue comments with progress, epic status synced to GitHub

**Progress Visibility:**
- Before: Progress only visible in local files, hard to see completion percentage
- After: Completion stats (e.g., "6/8 tasks, 75%"), archive includes final task metrics

**Parallel Work Opportunities:**
- Before: Sequential work (wait for one task to finish), manual tracking of task dependencies
- After: `bd-parallel-tasks.sh` shows ready tasks, team members can pick up parallel work

### Key Design Decisions

1. **Optional Integration:** Beads is optional. DevDocs works standalone with markdown-only tracking.

2. **One-Way Sync:** Beads → GitHub (not bidirectional). Beads is the source of truth.

3. **Git-Ignored State:** `.beads/` directory not committed. Task state is local, sync via GitHub.

4. **Automatic Detection:** Scripts auto-detect Beads using `command -v bd`.

5. **Graceful Degradation:** If Beads unavailable, scripts skip Beads features silently.

### Next Steps

**For Solo Developers:**
1. Use DevDocs standalone (no Beads needed)
2. Focus on session handoff and progress tracking
3. Archive completed work for future reference

**For Team Environments:**
1. Install Beads for task coordination
2. Use `--beads` flag when creating devdocs
3. Run `bd-sync-to-github.sh` regularly to update issues
4. Use `bd-parallel-tasks.sh` to find work for team members

**Testing the Integration:**

Follow the test scenarios in `TESTING.md`:
- Scenario 4: Beads task start
- Scenario 5: Parallel work detection
- Scenario 6: Progress sync
- Scenario 7: Task completion
- Scenario 9: Full end-to-end workflow

**Contributing Improvements:**

Potential enhancements:
1. Auto-sync on commit: Git hook to run `bd-sync-to-github.sh`
2. Slack integration: Notify team when tasks become ready
3. Time tracking: Estimate vs actual time for tasks
4. Burndown charts: Visual progress tracking
5. Task templates: Reusable task structures for common patterns

### Troubleshooting

**Issue: Beads not detected by scripts**

Solution:
```bash
# Ensure Beads is in PATH
command -v bd
# Should output: /path/to/bd

# If not found, install or add to PATH
export PATH="$PATH:/path/to/beads/bin"
```

**Issue: Epic initialization fails**

Solution:
```bash
# Check plan.md structure
cat plan.md | grep "^## Phase"
# Should show phase headers

# Verify plan has tasks
./scripts/bd-from-plan.sh plan.md
# Should output JSON with tasks
```

**Issue: GitHub sync fails**

Solution:
```bash
# Verify GitHub CLI authenticated
gh auth status

# Check issue exists
gh issue view <issue-number>

# Test with dry-run
./scripts/bd-sync-to-github.sh <issue> <epic> --dry-run
```

For more help:
- See `TESTING.md` for test scenarios
- See `SKILL.md` for detailed workflow documentation
- Check script help: `./scripts/bd-init.sh --help`

## Quick Start (Copy-Paste)

**With Superpowers (Recommended):**
```bash
# Step 1: Run superpowers skills (creates specs in docs/plans/)
# - superpowers:brainstorming  → creates design spec
# - superpowers:writing-plans  → creates implementation plan

# Step 2: Create progress tracking (auto-detects superpowers)
./scripts/devdocs-create.sh <issue-number>
# Creates docs/plans/<feature>/progress.md with superpowers integration
```

**Standalone (No Superpowers):**
```bash
# Script auto-detects no superpowers, uses .github/devdocs/
./scripts/devdocs-create.sh <issue-number>
# Creates both plan.md and progress.md
```

**Full Superpowers Workflow:**
```
1. superpowers:brainstorming      → docs/plans/YYYY-MM-DD-feature-design.md
2. superpowers:writing-plans      → docs/plans/YYYY-MM-DD-feature.md
3. devdocs-create.sh <issue-num>  → docs/plans/feature/progress.md
4. superpowers:test-driven-development → Track TDD cycles in progress.md
5. superpowers:systematic-debugging    → Log debugging in progress.md
6. superpowers:verification-before-completion → Trigger completion
7. superpowers:requesting-code-review  → Review workflow
8. superpowers:finishing-a-development-branch → Merge/PR decision
9. archive-devdocs.sh <feature>   → docs/plans/archive/feature.md
```

**Create new issue + devdocs together:**
```bash
./scripts/devdocs-create.sh --new --title "Implement feature analytics" --label "feature,analytics" --body "Add trend analysis"
```

**Manual approach (standalone task):**
```bash
mkdir -p docs/plans/<task-name>
# Create plan.md and progress.md using templates
```

**Resuming a task (tell the agent):**
```
Continue work on <task-name>. Read docs/plans/<task-name>/progress.md for current state.
```

**Ending a session (agent should do this):**
1. Update `progress.md` with current status
2. Note blockers and next steps
3. Commit changes

**Archiving a completed task:**
```bash
./scripts/archive-devdocs.sh <task-name>
```

## Automation Scripts

### devdocs-create.sh

The `scripts/devdocs-create.sh` script automates the entire setup with two modes:

### Mode 1: From Existing Issue
```bash
./scripts/devdocs-create.sh 123
```

### Mode 2: Create New Issue + DevDocs
```bash
./scripts/devdocs-create.sh --new --title "Implement feature analytics" --label "feature,analytics" --body "Add trend analysis"
```

**Options:**
| Flag | Description |
|------|-------------|
| `--new`, `-n` | Create a new GitHub issue |
| `--title`, `-t` | Issue title (required with --new) |
| `--label`, `-l` | Comma-separated labels |
| `--body`, `-b` | Issue description |
| `--help`, `-h` | Show help |

**What it does:**
1. ✅ Creates new issue OR fetches existing issue details from GitHub
2. ✅ Creates `devdocs/issue-<number>-<slug>/` directory
3. ✅ Generates `plan.md` pre-filled with issue body as the goal
4. ✅ Generates `progress.md` with issue link and ready-to-use structure
5. ✅ Adds a comment to the issue linking back to devdocs (bidirectional)

**Requirements:**
- GitHub CLI installed and authenticated (`gh auth login`)

### archive-devdocs.sh

The `scripts/archive-devdocs.sh` script automates the completion checklist:

```bash
./scripts/archive-devdocs.sh issue-123-feature-name
```

**What it does:**
1. ✅ Creates archive summary from plan.md and progress.md
2. ✅ Prompts for tags and key gotchas
3. ✅ Adds entry to archive/INDEX.md
4. ✅ Optionally adds comment to linked GitHub issue
5. ✅ Optionally deletes working devdocs directory

## GitHub Issues Integration

DevDocs works alongside GitHub Issues for the best of both worlds:

| Concern | GitHub Issues | DevDocs |
|---------|---------------|---------|
| **Team visibility** | ✅ Project boards, notifications | ❌ Requires reading files |
| **Session continuity** | ❌ No context handoff | ✅ Detailed agent handoffs |
| **PR linking** | ✅ Auto-close with `Closes #123` | ❌ Manual |
| **Blocker escalation** | ✅ @mentions, labels | ❌ Just text |
| **Progress tracking** | 🟡 Task lists in issue body | ✅ Detailed checklists |
| **Failed approaches** | ❌ Clutters issue | ✅ Dedicated section |

### Recommended Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. CREATE: GitHub Issue #123                                    │
│     gh issue create --title "..." --label "feature" --body "..." │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│  2. AUTOMATE: Run devdocs-create script                          │
│     ./scripts/devdocs-create.sh 123                              │
│     → Creates devdocs + adds comment to issue                    │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│  3. IMPLEMENT: Work with AI agent using devdocs                  │
│     .github/devdocs/issue-123-<short-name>/                      │
│       ├── plan.md     (pre-filled from issue body)               │
│       └── progress.md (session handoffs, failed approaches)      │
└─────────────────────────────────────────────────────────────────┘
                                ↓
┌─────────────────────────────────────────────────────────────────┐
│  4. COMPLETE: PRs auto-close issue                               │
│     PR description: "Closes #123"                                │
│     Archive devdocs → .github/devdocs/archive/                   │
└─────────────────────────────────────────────────────────────────┘
```

### Naming Convention

| Type | Directory Name | Example |
|------|----------------|---------|
| Issue-linked | `issue-<number>-<short-name>/` | `issue-123-feature-analytics/` |
| Standalone | `<descriptive-name>/` | `api-refactor/` |

## Purpose

Context window limits are the biggest practical challenge in AI-assisted development. When you hit ~80% context usage, the model triggers "compaction"—a summarization that loses critical details. Work doesn't survive compaction reliably.

**The solution is persisting state to disk.**

> **Key Insight:** Your own compaction is better than automatic compaction. Persist state to disk before context gets high.

## Directory Structure

```
devdocs/
├── README.md           # This file - explains the methodology
├── DEBUGGING.md        # Active reference: how to debug common issues
├── templates/          # Templates for new tasks
│   ├── plan.template.md
│   └── progress.template.md
├── issue-123-<name>/   # Issue-linked task (preferred)
│   ├── plan.md         # Goals, phases, approach (links to #123)
│   └── progress.md     # Current status, checkboxes, blockers
├── <task-name>/        # Standalone task
│   ├── plan.md
│   └── progress.md
└── archive/            # Completed task summaries (permanent reference)
    ├── INDEX.md        # Searchable index of all archived tasks
    └── <task-name>.md  # Condensed summary with key learnings
```

## Workflow

### 1. Start a Task

Create `devdocs/<task-name>/plan.md` with:
- GitHub issue link (if applicable)
- Goal and scope
- Implementation phases
- Testing strategy
- Success criteria

```bash
# Example: Starting an issue-linked task
gh issue create --title "Implement feature analytics" --label "feature" --body "Add feature trend analysis"
# Assume this creates issue #42

mkdir -p .github/devdocs/issue-42-feature-analytics
cp .github/devdocs/templates/plan.template.md .github/devdocs/issue-42-feature-analytics/plan.md
cp .github/devdocs/templates/progress.template.md .github/devdocs/issue-42-feature-analytics/progress.md
```

### 2. Track Progress

Update `progress.md` as work proceeds:

```markdown
## Phase 1: Data Models
- [x] Create analytics data structures
- [x] Add unit tests for calculations
- [ ] Implement trend detection  ← Currently here
- [ ] Write integration tests

## Blockers
- Need clarification on chart library choice
```

### 3. End Session (at ~60-70% context)

1. Ensure `progress.md` is updated with current state
2. Note any blockers or decisions needed
3. Start a new session

**To resume:** Tell the new session:
```
Continue work on <task-name>. Read .github/devdocs/<task-name>/progress.md for current state.
```

### 4. Complete Task

When the task is finished, follow the **Completion Checklist** in `progress.md`:

1. **Update Feature Documentation** in `{{DOCS_PATH}}/features/`:
   - Update `Implementation_Status.md` with completed work
   - Add **Implementation History** link pointing to the archive
   - Mark phases complete in `Implementation_Plan.md`

2. **Feed back discoveries** to `.github/devdocs/DEBUGGING.md`:
   - Add any new debugging patterns
   - Document gotchas for future sessions

3. **Update the archive index** at `archive/INDEX.md`

4. **Create archive summary** at `archive/<task-name>.md` with key learnings, decisions, and gotchas

> **Important:** DevDocs is temporary working memory. Feature Documentation is the permanent record. Always update Feature Documentation when completing a task.

## Context Management Guidelines

**General Guidelines for Managing Context:**
- **Below ~50%:** Optimal range for continued work
- **Around 50-70%:** Still good performance, but consider planning session handoff after completing current phase
- **Around 70-80%:** Performance may degrade, prioritize finishing current task and preparing handoff
- **Above ~80%:** High risk of automatic summarization, stop and persist state immediately

These are rough heuristics, not precise thresholds. When in doubt, persist state early rather than risk losing context.

### Context-Saving Tips for Agents

1. **Read strategically:** Read large chunks once, not small pieces repeatedly
2. **Use grep first:** `grep -n` to find line numbers before reading files
3. **Skip redundant docs:** If you've read `AGENTS.md`, skip agent files that duplicate it
4. **Batch edits:** Use `multi_replace_string_in_file` for multiple changes
5. **Persist early:** If a task seems complex, create devdocs immediately

## What Survives Across Sessions

✅ **Survives:**
- Files on disk (code, tests, documentation)
- DevDocs (plan.md, progress.md)
- Git history

❌ **Doesn't survive:**
- In-memory context about failed approaches
- Nuanced understanding of specific decisions
- Agent's "train of thought"

**This is why written documentation matters—it's the only reliable memory.**

## Relationship to Feature Documentation

| Location | Purpose | When to Use |
|----------|---------|-------------|
| `devdocs/<task>/` | **Session continuity** - temporary working state | During active development |
| `{{DOCS_PATH}}/features/` | **Permanent documentation** - specs, plans, status | Feature specifications, long-term reference |

### Complete Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│  1. PLAN: Create feature spec                                       │
│     → {{DOCS_PATH}}/features/
│       ├── FeatureName.md (requirements, user stories)               │
│       ├── Implementation_Plan.md (scope, phases, architecture)      │
│       └── Implementation_Status.md (progress tracking)              │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  2. IMPLEMENT: Use DevDocs for session continuity                   │
│     → .github/devdocs/<task>/                                       │
│       ├── plan.md (session-specific goals, failed approaches)       │
│       └── progress.md (current status, blockers, handoff TL;DR)     │
└─────────────────────────────────────────────────────────────────────┘
                                  ↓
┌─────────────────────────────────────────────────────────────────────┐
│  3. COMPLETE: Follow Completion Checklist                           │
│     a. Update Feature Docs + add Implementation History link        │
│           ←─────────────── bidirectional ──────────────→                │
│     b. Feed discoveries back to DEBUGGING.md                        │
│     c. Update archive/INDEX.md                                      │
│     d. Create archive/<task>.md (permanent reference)               │
└─────────────────────────────────────────────────────────────────────┘
```

### Bidirectional Linking

Feature docs and archives should reference each other:

**In Feature Documentation** (`{{DOCS_PATH}}/features/<Feature>/Implementation_Status.md`):
```markdown
## Implementation History
- [example-task-migration](/.github/devdocs/archive/example-task-migration.md) - V1→V2 schema migration, backward compatibility layer
```

**In Archive** (`.github/devdocs/archive/<task>.md`):
```markdown
## Related Documentation
- Feature docs: `{{DOCS_PATH}}/features/<Feature>/`
```

### Examples in This Project

**Example Feature** (completed):
- Permanent docs: `{{DOCS_PATH}}/features/<Feature>/`
  - `Feature_V1.md`, `Feature_V2.md` - Version specifications
  - `Feature_Schemas.md` - Schema documentation
  - `schemas/` - Schema files
- Archive: `.github/devdocs/archive/example-feature-v2-migration.md`

**Example Feature** (in progress):
- Permanent docs: `{{DOCS_PATH}}/features/<Feature>/`
  - `Feature.md` - Feature specification
  - `Implementation_Plan.md` - Phased plan with checkboxes
  - `Implementation_Status.md` - Current progress tracking

## Examples

### Example: In-Progress Task

**`devdocs/api-background-sync/plan.md`:**
```markdown
# API Background Sync - Plan

## Goal
Implement background data sync from external API to backend.

## Phases
1. Background task registration
2. Incremental sync logic
3. Error handling and retry
4. Testing

## Success Criteria
- Background sync runs every 15 minutes
- Handles offline gracefully
- No data loss on app termination
```

**`devdocs/api-background-sync/progress.md`:**
```markdown
# API Background Sync - Progress

## Current Phase: Phase 2 - Incremental Sync

## Phase 1: Background Task Registration ✅
- [x] Register background task scheduler
- [x] Create BackgroundSyncTask class
- [x] Test task scheduling

## Phase 2: Incremental Sync Logic
- [x] Implement cursor-based pagination
- [ ] Add batch upload to backend ← Currently here
- [ ] Handle large datasets

## Blockers
- Need to decide batch size for backend writes
```

### Example: Archived Task

**`devdocs/archive/example-feature-v2-migration.md`:**
```markdown
# Example Feature V2 Migration - Summary

## What Was Built
- Migrated feature from V1 to V2 JSON schema
- Added backward compatibility layer
- Updated all view models

## Key Decisions
- Used strategy pattern for schema versioning
- Kept V1 parser for legacy data migration
- 30-day deprecation period for old format

## Gotchas
- V1 timestamps were strings, V2 uses ISO8601
- Null handling differs between versions
- Unit tests need both V1 and V2 fixtures
```

## References

- [AGENTS.md](../../AGENTS.md) - Project-wide agent instructions

### Development Documentation

- `{{DOCS_PATH}}/Development/CLI_Tools.md` - GitHub CLI, backend CLI, build tool usage
- `{{DOCS_PATH}}/Development/CommitlintConfiguration.md` - Commit message types and branch naming
