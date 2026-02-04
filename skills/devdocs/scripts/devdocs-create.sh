#!/bin/bash
# devdocs-create.sh - Create devdocs synchronized with GitHub Issues
#
# Usage:
#   From existing issue:
#     ./scripts/devdocs-create.sh <issue-number>
#     ./scripts/devdocs-create.sh 123
#
#   Create new issue + devdocs:
#     ./scripts/devdocs-create.sh --new --title "Title" [--label "label1,label2"] [--body "Description"]
#     ./scripts/devdocs-create.sh --new --title "Implement feature" --label "feature"
#
# What it does:
#   1. Creates or fetches GitHub issue
#   2. Creates devdocs directory: .github/devdocs/issue-<number>-<slug>/
#   3. Generates plan.md with issue body pre-filled
#   4. Generates progress.md with issue link
#   5. Adds a comment to the GitHub issue linking back to devdocs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check dependencies
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI not installed. Install: brew install gh${NC}"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI not authenticated. Run: gh auth login${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq not installed. Install: brew install jq${NC}"
    exit 1
fi

# Parse arguments
CREATE_NEW=false
ISSUE_NUMBER=""
ISSUE_TITLE=""
ISSUE_LABELS=""
ISSUE_BODY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --new|-n)
            CREATE_NEW=true
            shift
            ;;
        --title|-t)
            ISSUE_TITLE="$2"
            shift 2
            ;;
        --label|-l)
            ISSUE_LABELS="$2"
            shift 2
            ;;
        --body|-b)
            ISSUE_BODY="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage:"
            echo "  From existing issue:"
            echo "    $0 <issue-number>"
            echo ""
            echo "  Create new issue + devdocs:"
            echo "    $0 --new --title \"Title\" [--label \"label1,label2\"] [--body \"Description\"]"
            echo ""
            echo "Options:"
            echo "  --new, -n       Create a new GitHub issue"
            echo "  --title, -t     Issue title (required with --new)"
            echo "  --label, -l     Comma-separated labels"
            echo "  --body, -b      Issue body/description"
            echo "  --help, -h      Show this help"
            exit 0
            ;;
        *)
            # Assume it's an issue number
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                ISSUE_NUMBER="$1"
            else
                echo -e "${RED}❌ Unknown argument: $1${NC}"
                echo "Run '$0 --help' for usage"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ "$CREATE_NEW" = true ]; then
    if [ -z "$ISSUE_TITLE" ]; then
        echo -e "${RED}❌ --title is required when creating a new issue${NC}"
        echo "Usage: $0 --new --title \"Issue title\" [--label \"labels\"] [--body \"description\"]"
        exit 1
    fi
elif [ -z "$ISSUE_NUMBER" ]; then
    echo -e "${RED}❌ Usage: $0 <issue-number>${NC}"
    echo "   Or:    $0 --new --title \"Issue title\""
    echo "Run '$0 --help' for more options"
    exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"

# ═══════════════════════════════════════════════════════════════════════════════
# Auto-detect Superpowers Integration
# ═══════════════════════════════════════════════════════════════════════════════
USE_SUPERPOWERS=false
SUPERPOWERS_DESIGN_SPEC=""
SUPERPOWERS_PLAN_SPEC=""

# Check if docs/plans/ directory exists
if [ -d "$REPO_ROOT/docs/plans" ]; then
    echo -e "${BLUE}🔍 Detected docs/plans/ directory - checking for superpowers integration...${NC}"

    # Look for dated spec files (superpowers pattern: YYYY-MM-DD-*.md)
    SPEC_COUNT=$(find "$REPO_ROOT/docs/plans" -maxdepth 1 -name "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*.md" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$SPEC_COUNT" -gt 0 ]; then
        USE_SUPERPOWERS=true
        DEVDOCS_DIR="$REPO_ROOT/docs/plans"
        echo -e "${GREEN}✅ Superpowers integration detected - using docs/plans/${NC}"
        echo -e "${YELLOW}   Note: Will create progress.md only (superpowers specs replace plan.md)${NC}"
    else
        DEVDOCS_DIR="${DEVDOCS_ROOT:-$REPO_ROOT/.github/devdocs}"
        echo -e "${YELLOW}⚠️  docs/plans/ exists but no superpowers specs found${NC}"
        echo -e "${YELLOW}   Using .github/devdocs/ for standalone workflow${NC}"
    fi
else
    DEVDOCS_DIR="${DEVDOCS_ROOT:-$REPO_ROOT/.github/devdocs}"
    echo -e "${BLUE}ℹ️  No docs/plans/ directory - using standalone workflow${NC}"
    echo -e "${BLUE}   Location: ${DEVDOCS_DIR}${NC}"
fi

# Create new issue if requested
if [ "$CREATE_NEW" = true ]; then
    echo -e "${BLUE}📝 Creating new GitHub issue...${NC}"

    # Build gh issue create command
    CREATE_CMD="gh issue create --title \"$ISSUE_TITLE\""

    if [ -n "$ISSUE_LABELS" ]; then
        CREATE_CMD="$CREATE_CMD --label \"$ISSUE_LABELS\""
    fi

    if [ -n "$ISSUE_BODY" ]; then
        CREATE_CMD="$CREATE_CMD --body \"$ISSUE_BODY\""
    else
        CREATE_CMD="$CREATE_CMD --body \"Created via devdocs-create script.\""
    fi

    # Create the issue and capture the URL
    ISSUE_URL=$(eval "$CREATE_CMD" 2>&1) || {
        echo -e "${RED}❌ Failed to create issue${NC}"
        echo "$ISSUE_URL"
        exit 1
    }

    # Extract issue number from URL (format: https://github.com/owner/repo/issues/123)
    ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')

    echo -e "${GREEN}✅ Created issue #${ISSUE_NUMBER}${NC}"
    echo -e "   ${BLUE}${ISSUE_URL}${NC}"
fi

# Fetch issue details
echo -e "${BLUE}📥 Fetching issue #${ISSUE_NUMBER} details...${NC}"

ISSUE_JSON=$(gh issue view "$ISSUE_NUMBER" --json title,body,labels,milestone,author,url 2>/dev/null) || {
    echo -e "${RED}❌ Failed to fetch issue #${ISSUE_NUMBER}. Does it exist?${NC}"
    exit 1
}

ISSUE_TITLE=$(echo "$ISSUE_JSON" | jq -r '.title')
ISSUE_BODY=$(echo "$ISSUE_JSON" | jq -r '.body // "No description provided."')
ISSUE_URL=$(echo "$ISSUE_JSON" | jq -r '.url')
ISSUE_AUTHOR=$(echo "$ISSUE_JSON" | jq -r '.author.login')
ISSUE_LABELS=$(echo "$ISSUE_JSON" | jq -r '[.labels[].name] | join(", ")')
ISSUE_MILESTONE=$(echo "$ISSUE_JSON" | jq -r '.milestone.title // "Backlog"')

# Create slug from title (lowercase, replace spaces/special chars with hyphens)
# Increased to 50 chars to reduce collision risk
ISSUE_SLUG=$(echo "$ISSUE_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | cut -c1-50)

# Set directory structure based on superpowers detection
if [ "$USE_SUPERPOWERS" = true ]; then
    # With superpowers: use feature name subdirectory, not issue-N-slug
    FEATURE_NAME="${ISSUE_SLUG}"
    TASK_DIR="$DEVDOCS_DIR/${FEATURE_NAME}"
    PROGRESS_FILE="$TASK_DIR/progress.md"
    # No plan.md - superpowers specs replace it

    # Try to find existing superpowers specs for this feature
    SUPERPOWERS_DESIGN_SPEC=$(find "$DEVDOCS_DIR" -maxdepth 1 -name "*-${FEATURE_NAME}-design.md" 2>/dev/null | head -1)
    SUPERPOWERS_PLAN_SPEC=$(find "$DEVDOCS_DIR" -maxdepth 1 -name "*-${FEATURE_NAME}.md" ! -name "*-design.md" 2>/dev/null | head -1)

    if [ -n "$SUPERPOWERS_DESIGN_SPEC" ]; then
        echo -e "${GREEN}✅ Found superpowers design spec: $(basename "$SUPERPOWERS_DESIGN_SPEC")${NC}"
    fi
    if [ -n "$SUPERPOWERS_PLAN_SPEC" ]; then
        echo -e "${GREEN}✅ Found superpowers plan spec: $(basename "$SUPERPOWERS_PLAN_SPEC")${NC}"
    fi

    if [ -z "$SUPERPOWERS_DESIGN_SPEC" ] && [ -z "$SUPERPOWERS_PLAN_SPEC" ]; then
        echo -e "${YELLOW}⚠️  No superpowers specs found for '${FEATURE_NAME}'${NC}"
        echo -e "${YELLOW}   You should run superpowers:brainstorming and superpowers:writing-plans first${NC}"
        echo -e "${YELLOW}   Or this script will create progress.md pointing to non-existent specs${NC}"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Aborted. Run superpowers skills first, then re-run this script.${NC}"
            exit 0
        fi
    fi
else
    # Standalone: use issue-N-slug directory
    TASK_DIR="$DEVDOCS_DIR/issue-${ISSUE_NUMBER}-${ISSUE_SLUG}"
    PLAN_FILE="$TASK_DIR/plan.md"
    PROGRESS_FILE="$TASK_DIR/progress.md"
fi

# Check if devdocs already exists
if [ -d "$TASK_DIR" ]; then
    echo -e "${YELLOW}⚠️  DevDocs already exists: $TASK_DIR${NC}"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted.${NC}"
        exit 0
    fi
fi

# Create directory
echo -e "${BLUE}📁 Creating devdocs at: $TASK_DIR${NC}"
mkdir -p "$TASK_DIR"

# Get current date
TODAY=$(date +%Y-%m-%d)

# ═══════════════════════════════════════════════════════════════════════════════
# Generate plan.md (only for standalone, NOT with superpowers)
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$USE_SUPERPOWERS" = false ]; then
    echo -e "${BLUE}📝 Creating plan.md...${NC}"
    cat > "$PLAN_FILE" << EOF
# ${ISSUE_TITLE} - Plan

> Auto-generated from GitHub Issue [#${ISSUE_NUMBER}](${ISSUE_URL}) on ${TODAY}
>
> **Reference:** See [\`AGENTS.md\`](../../../AGENTS.md) for all coding standards.

## GitHub Issue

- **Issue:** [#${ISSUE_NUMBER}](${ISSUE_URL})
- **Author:** @${ISSUE_AUTHOR}
- **Labels:** ${ISSUE_LABELS:-"none"}
- **Milestone:** ${ISSUE_MILESTONE}

## Goal

${ISSUE_BODY}

---

## Scope

**✅ In Scope:**
- [ ] TODO: Define specific deliverables

**❌ Out of Scope:**
- [ ] TODO: Define what's explicitly excluded

## Approach

### Phase 1: [Phase Name]
- [ ] Step 1
- [ ] Step 2
- [ ] Step 3

### Phase 2: [Phase Name]
- [ ] Step 1
- [ ] Step 2

## Testing Strategy

- [ ] Unit tests for [component]
- [ ] Integration tests for [flow]
- [ ] Manual testing checklist:
  - [ ] Test case 1
  - [ ] Test case 2

## Success Criteria

- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] All tests pass
- [ ] Linter passes with 0 errors
- [ ] Code reviewed and merged

## Dependencies

- [Dependency 1: status]

## Estimated Effort

- **Total:** [X hours/days]
- **Phase 1:** [estimate]
- **Phase 2:** [estimate]

## Notes

[Any additional context, decisions made, or assumptions]

## Failed Approaches Log

> **Track what didn't work.** This survives across sessions and prevents repeating mistakes.

| Approach | Why It Failed | Date |
|----------|---------------|------|
| — | — | — |
EOF

    echo -e "${GREEN}✅ Created plan.md${NC}"
else
    echo -e "${YELLOW}⚠️  Skipping plan.md (superpowers specs replace it)${NC}"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Generate progress.md (different format for superpowers vs standalone)
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${BLUE}📝 Creating progress.md...${NC}"

if [ "$USE_SUPERPOWERS" = true ]; then
    # Progress.md with superpowers integration
    DESIGN_LINK=""
    PLAN_LINK=""

    if [ -n "$SUPERPOWERS_DESIGN_SPEC" ]; then
        DESIGN_LINK="**Superpowers Design:** [$(basename "$SUPERPOWERS_DESIGN_SPEC")](../$(basename "$SUPERPOWERS_DESIGN_SPEC"))"
    fi

    if [ -n "$SUPERPOWERS_PLAN_SPEC" ]; then
        PLAN_LINK="**Superpowers Plan:** [$(basename "$SUPERPOWERS_PLAN_SPEC")](../$(basename "$SUPERPOWERS_PLAN_SPEC"))"
    fi

    cat > "$PROGRESS_FILE" << EOF
# ${ISSUE_TITLE} - Progress

> This file tracks session-to-session progress. Update before ending each session.

${DESIGN_LINK}
${PLAN_LINK}
**GitHub Issue:** [#${ISSUE_NUMBER}](${ISSUE_URL})
**Last Updated:** ${TODAY}
**Current Phase:** [Phase X - from superpowers plan]
**Overall Status:** 🟡 In Progress

---

## Session Handoff (TL;DR)

> **For instant context resumption.** Update this section at the end of each session.

| Field | Value |
|-------|-------|
| **Next Action** | [Specific next step from superpowers plan] |
| **Context Needed** | [Files to read] |
| **Blocker** | None |
| **Failed Approaches** | None |
| **Current Superpowers Skill** | [test-driven-development / systematic-debugging / none] |

---

## Superpowers Workflow Tracking

**Completed:**
- [x] brainstorming (design spec created)
- [x] writing-plans (implementation plan created)

**In Progress:**
- [ ] test-driven-development (TDD cycles tracked below)
- [ ] systematic-debugging (debugging log below if needed)

**Next:**
- [ ] verification-before-completion
- [ ] requesting-code-review
- [ ] finishing-a-development-branch

---

## TDD Cycle Tracking

> Track RED-GREEN-REFACTOR cycles when using superpowers:test-driven-development

| Cycle | Feature/Test | RED | GREEN | REFACTOR | Notes |
|-------|--------------|-----|-------|----------|-------|
| 1 | [Feature name] | ⬜ | ⬜ | ⬜ | Planned |

**TDD Notes:**
- [Observations about TDD process]

---

## Debugging Log

> Log root cause analysis from superpowers:systematic-debugging sessions

**Session [N] - [Date]** (if needed)

| Phase | Status | Findings |
|-------|--------|----------|
| 1. Reproduce | ⬜ | [Steps to reproduce] |
| 2. Isolate | ⬜ | [Where bug occurs] |
| 3. Root Cause | ⬜ | [Why it happens] |
| 4. Verify Fix | ⬜ | [How fix was tested] |

---

## Quick Status

> Reference the phases from the superpowers plan spec

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 1 | 🟡 In Progress | [From superpowers plan] |
| Phase 2 | ⬜ Not Started | — |

---

## Phase 1: [Phase Name from Superpowers Plan] 🟡

> Copy phase tasks from superpowers:writing-plans spec

- [ ] **Current →** First task
- [ ] Next task

**Session Notes:**
- [What was accomplished]

---

## Phase 2: [Phase Name from Superpowers Plan] ⬜

- [ ] Item 1
- [ ] Item 2

---

## Blockers

- [ ] None currently

## Decisions Made

| Decision | Rationale | Date |
|----------|-----------|------|
| — | — | — |

## Files Changed

Key files touched during this task:
- (none yet)

## Next Session

**To resume this task, tell the agent:**
\`\`\`
Continue work on ${FEATURE_NAME}. Read docs/plans/${FEATURE_NAME}/progress.md for current state.
Reference the superpowers plan for phases and tasks.
\`\`\`

**Priority for next session:**
1. [Most important next step from superpowers plan]

## Session Log

| Date | Context % | Work Done | Notes |
|------|-----------|-----------|-------|
| ${TODAY} | ~10% | Created progress tracking | Initial setup with superpowers |

---

## Completion Checklist (With Superpowers)

> **Use this checklist when the task is complete.**

- [ ] **Run verification** (superpowers:verification-before-completion)
  - [ ] All tests pass
  - [ ] Build succeeds
  - [ ] No linter warnings

- [ ] **Request code review** (superpowers:requesting-code-review)
  - [ ] Address all feedback

- [ ] **Finish development branch** (superpowers:finishing-a-development-branch)
  - [ ] Decide: Merge / Create PR / Clean up

- [ ] **Archive devdocs**
  - [ ] Run: \`./scripts/archive-devdocs.sh ${FEATURE_NAME}\`
  - [ ] Archive created in \`docs/plans/archive/${FEATURE_NAME}.md\`
  - [ ] Entry added to \`docs/plans/archive/INDEX.md\`
  - [ ] Superpowers specs remain in \`docs/plans/\` (do not delete!)

- [ ] **Close GitHub Issue**
  - [ ] Final PR includes \`Closes #${ISSUE_NUMBER}\`

- [ ] **Feed back discoveries** to \`skills/devdocs/DEBUGGING.md\`
  - [ ] Add debugging patterns and gotchas
EOF

else
    # Progress.md for standalone (no superpowers)
    cat > "$PROGRESS_FILE" << EOF
# ${ISSUE_TITLE} - Progress

> This file tracks session-to-session progress. Update before ending each session.

**Plan:** [plan.md](plan.md)
**GitHub Issue:** [#${ISSUE_NUMBER}](${ISSUE_URL})
**Last Updated:** ${TODAY}
**Current Phase:** Phase 1 - [Name]
**Overall Status:** 🟡 In Progress

---

## Session Handoff (TL;DR)

> **For instant context resumption.** Update this section at the end of each session.

| Field | Value |
|-------|-------|
| **Next Action** | [Specific next step] |
| **Context Needed** | [Files to read] |
| **Blocker** | None |
| **Failed Approaches** | None |

---

## Quick Status

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 1 | 🟡 In Progress | — |
| Phase 2 | ⬜ Not Started | — |

---

## Phase 1: [Phase Name] 🟡

- [ ] **Current →** First task
- [ ] Next task

**Session Notes:**
- [What was accomplished]

---

## Phase 2: [Phase Name] ⬜

- [ ] Item 1
- [ ] Item 2

---

## Blockers

- [ ] None currently

## Decisions Made

| Decision | Rationale | Date |
|----------|-----------|------|
| — | — | — |

## Files Changed

Key files touched during this task:
- (none yet)

## Next Session

**To resume this task, tell the agent:**
\`\`\`
Continue work on issue-${ISSUE_NUMBER}-${ISSUE_SLUG}. Read .github/devdocs/issue-${ISSUE_NUMBER}-${ISSUE_SLUG}/progress.md for current state.
\`\`\`

**Priority for next session:**
1. [Most important next step]

## Session Log

| Date | Context % | Work Done | Notes |
|------|-----------|-----------|-------|
| ${TODAY} | ~10% | Created devdocs | Initial setup |

---

## Completion Checklist (Standalone)

> **Use this checklist when the task is complete.**

- [ ] **Verify completion**
  - [ ] All tests pass
  - [ ] Build succeeds
  - [ ] Code reviewed

- [ ] **Archive devdocs**
  - [ ] Run: \`./scripts/archive-devdocs.sh issue-${ISSUE_NUMBER}-${ISSUE_SLUG}\`
  - [ ] Archive created in \`.github/devdocs/archive/issue-${ISSUE_NUMBER}-${ISSUE_SLUG}.md\`

- [ ] **Close GitHub Issue**
  - [ ] Final PR includes \`Closes #${ISSUE_NUMBER}\`

- [ ] **Update documentation** (if applicable)
  - [ ] Feature docs updated
EOF

fi

echo -e "${GREEN}✅ Created progress.md${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# Beads Integration
# ═══════════════════════════════════════════════════════════════════════════════
BEADS_EPIC_ID=""

if command -v bd &> /dev/null; then
    echo -e "${BLUE}🔷 Initializing Beads integration...${NC}"

    # Initialize Beads if needed
    "$REPO_ROOT/skills/devdocs/scripts/bd-init.sh" 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Beads initialization failed - continuing without Beads${NC}"
    }

    if [ -d ".beads" ]; then
        # Sanitize ISSUE_TITLE for safe passing to bd (remove backticks and $)
        SAFE_ISSUE_TITLE="${ISSUE_TITLE//[\`\$]/}"

        # Create epic with proper JSON validation
        BEADS_OUTPUT=$(bd create "$SAFE_ISSUE_TITLE" --epic \
            --meta github_issue="$ISSUE_NUMBER" \
            --meta github_url="$ISSUE_URL" \
            --meta devdocs_path="$TASK_DIR" \
            --json 2>&1)

        if echo "$BEADS_OUTPUT" | jq -e . >/dev/null 2>&1; then
            BEADS_EPIC_ID=$(echo "$BEADS_OUTPUT" | jq -r '.id')
        else
            echo -e "${YELLOW}⚠️  Failed to create Beads epic - invalid response${NC}"
            BEADS_EPIC_ID=""
        fi

        if [ -n "$BEADS_EPIC_ID" ]; then
            echo -e "${GREEN}✅ Created Beads epic: $BEADS_EPIC_ID${NC}"

            # If superpowers plan exists, create phase tasks
            if [ -n "$SUPERPOWERS_PLAN_SPEC" ] && [ -f "$SUPERPOWERS_PLAN_SPEC" ]; then
                echo -e "${BLUE}📋 Creating phase tasks from plan...${NC}"
                "$REPO_ROOT/skills/devdocs/scripts/bd-from-plan.sh" "$SUPERPOWERS_PLAN_SPEC" "$BEADS_EPIC_ID" 2>/dev/null || {
                    echo -e "${YELLOW}⚠️  Failed to create tasks from plan${NC}"
                }
            fi

            # Update progress.md with epic ID
            sed -i '' "/^\*\*GitHub Issue:\*\*/a\\
**Beads Epic:** \`$BEADS_EPIC_ID\`
" "$PROGRESS_FILE"

            echo -e "${GREEN}✅ Updated progress.md with Beads epic ID${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Beads not installed - using markdown-only tracking${NC}"
    echo -e "   Install for enhanced task tracking: ${BLUE}npm install -g beads-ai${NC}"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Add comment to GitHub issue with link to devdocs
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$USE_SUPERPOWERS" = true ]; then
    DEVDOCS_RELATIVE_PATH="docs/plans/${FEATURE_NAME}/"
    COMMENT_BODY="🤖 **DevDocs Progress Tracking Created**

Session continuity with **superpowers** integration:
- [\`${DEVDOCS_RELATIVE_PATH}progress.md\`](${DEVDOCS_RELATIVE_PATH}progress.md) - Session handoffs, TDD cycles, debugging log"

    if [ -n "$BEADS_EPIC_ID" ]; then
        COMMENT_BODY="$COMMENT_BODY

**Beads Task Tracking:** \`$BEADS_EPIC_ID\`
- Query ready tasks: \`bd ready --parent $BEADS_EPIC_ID\`
- View status: \`bd status $BEADS_EPIC_ID\`"
    fi

    # Determine filenames for design and plan specs
    if [ -n "$SUPERPOWERS_DESIGN_SPEC" ] && [ -f "$SUPERPOWERS_DESIGN_SPEC" ]; then
        DESIGN_FILENAME=$(basename "$SUPERPOWERS_DESIGN_SPEC")
    else
        DESIGN_FILENAME="YYYY-MM-DD-${FEATURE_NAME}-design.md"
    fi

    if [ -n "$SUPERPOWERS_PLAN_SPEC" ] && [ -f "$SUPERPOWERS_PLAN_SPEC" ]; then
        PLAN_FILENAME=$(basename "$SUPERPOWERS_PLAN_SPEC")
    else
        PLAN_FILENAME="YYYY-MM-DD-${FEATURE_NAME}.md"
    fi

    COMMENT_BODY="$COMMENT_BODY

Plan files (created by superpowers):
- [\`docs/plans/${DESIGN_FILENAME}\`] - Design specification
- [\`docs/plans/${PLAN_FILENAME}\`] - Implementation plan

To resume work on this issue, tell the agent:
\`\`\`
Continue work on ${FEATURE_NAME}. Read docs/plans/${FEATURE_NAME}/progress.md for current state.
\`\`\`"
else
    DEVDOCS_RELATIVE_PATH=".github/devdocs/issue-${ISSUE_NUMBER}-${ISSUE_SLUG}/"
    COMMENT_BODY="🤖 **DevDocs Created**

Session continuity files for AI-assisted development:
- [\`${DEVDOCS_RELATIVE_PATH}plan.md\`](${DEVDOCS_RELATIVE_PATH}plan.md) - Goals, scope, approach
- [\`${DEVDOCS_RELATIVE_PATH}progress.md\`](${DEVDOCS_RELATIVE_PATH}progress.md) - Session handoffs, status"

    if [ -n "$BEADS_EPIC_ID" ]; then
        COMMENT_BODY="$COMMENT_BODY

**Beads Task Tracking:** \`$BEADS_EPIC_ID\`"
    fi

    COMMENT_BODY="$COMMENT_BODY

To resume work on this issue, tell the agent:
\`\`\`
Continue work on issue-${ISSUE_NUMBER}-${ISSUE_SLUG}. Read .github/devdocs/issue-${ISSUE_NUMBER}-${ISSUE_SLUG}/progress.md for current state.
\`\`\`"
fi

echo -e "${BLUE}💬 Adding comment to issue #${ISSUE_NUMBER}...${NC}"
gh issue comment "$ISSUE_NUMBER" --body "$COMMENT_BODY"

echo -e "${GREEN}✅ Added bidirectional link to issue${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ DevDocs created successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "📁 Location: ${BLUE}${TASK_DIR}${NC}"
echo -e "📋 Issue:    ${BLUE}${ISSUE_URL}${NC}"
echo ""

if [ "$USE_SUPERPOWERS" = true ]; then
    echo -e "⚡ ${YELLOW}Superpowers Integration Detected${NC}"
    echo ""
    echo -e "Next steps:"
    echo -e "  1. ${BLUE}Ensure superpowers specs exist:${NC}"
    echo -e "     - Run ${YELLOW}superpowers:brainstorming${NC} (creates design spec)"
    echo -e "     - Run ${YELLOW}superpowers:writing-plans${NC} (creates implementation plan)"
    echo -e "  2. ${BLUE}Start implementation:${NC}"
    echo -e "     ${YELLOW}Work on ${FEATURE_NAME}. Read docs/plans/${FEATURE_NAME}/progress.md for tracking.${NC}"
    echo -e "  3. ${BLUE}Use superpowers skills during development:${NC}"
    echo -e "     - ${YELLOW}test-driven-development${NC} (track TDD cycles)"
    echo -e "     - ${YELLOW}systematic-debugging${NC} (log debugging sessions)"
    echo -e "     - ${YELLOW}verification-before-completion${NC} (before finishing)"
    echo -e "     - ${YELLOW}requesting-code-review${NC} (review workflow)"
    echo -e "     - ${YELLOW}finishing-a-development-branch${NC} (merge/PR decision)"
else
    echo -e "To start working, tell the agent:"
    echo -e "${YELLOW}  Work on issue #${ISSUE_NUMBER}. Read .github/devdocs/issue-${ISSUE_NUMBER}-${ISSUE_SLUG}/plan.md for context.${NC}"
fi

echo ""
