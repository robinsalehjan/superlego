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
DEVDOCS_DIR="${DEVDOCS_ROOT:-$REPO_ROOT/.github/devdocs}"

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

TASK_DIR="$DEVDOCS_DIR/issue-${ISSUE_NUMBER}-${ISSUE_SLUG}"
PLAN_FILE="$TASK_DIR/plan.md"
PROGRESS_FILE="$TASK_DIR/progress.md"

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

# Generate plan.md
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

# Generate progress.md
cat > "$PROGRESS_FILE" << EOF
# ${ISSUE_TITLE} - Progress

> This file tracks session-to-session progress. Update before ending each session.
>
> **Quick Commands:** See [\`AGENTS.md\` §15](../../../AGENTS.md#15-quick-reference-copy-paste-for-agents) for build/test/lint commands.

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

## Completion Checklist

> **Use this checklist when the task is complete.**

- [ ] **Close GitHub Issue**
  - [ ] Ensure final PR includes \`Closes #${ISSUE_NUMBER}\` in description
  - [ ] Or close manually: \`gh issue close ${ISSUE_NUMBER} --comment "Completed"\`
- [ ] **Update Feature Documentation** in \`{{DOCS_PATH}}/features/<Feature>/\`
  - [ ] Update \`Implementation_Status.md\` with completed work
  - [ ] Add implementation history link
  - [ ] Mark phases complete in \`Implementation_Plan.md\`
- [ ] **Feed back debugging discoveries** to \`.github/devdocs/DEBUGGING.md\`
- [ ] **Update archive index** in \`.github/devdocs/archive/INDEX.md\`
- [ ] **Create archive summary** at \`.github/devdocs/archive/issue-${ISSUE_NUMBER}-${ISSUE_SLUG}.md\`
- [ ] **Delete working files** after archiving
EOF

echo -e "${GREEN}✅ Created plan.md and progress.md${NC}"

# Add comment to GitHub issue with link to devdocs
DEVDOCS_RELATIVE_PATH=".github/devdocs/issue-${ISSUE_NUMBER}-${ISSUE_SLUG}/"
COMMENT_BODY="🤖 **DevDocs Created**

Session continuity files for AI-assisted development:
- [\`${DEVDOCS_RELATIVE_PATH}plan.md\`](${DEVDOCS_RELATIVE_PATH}plan.md) - Goals, scope, approach
- [\`${DEVDOCS_RELATIVE_PATH}progress.md\`](${DEVDOCS_RELATIVE_PATH}progress.md) - Session handoffs, status

To resume work on this issue, tell the agent:
\`\`\`
Continue work on issue-${ISSUE_NUMBER}-${ISSUE_SLUG}. Read .github/devdocs/issue-${ISSUE_NUMBER}-${ISSUE_SLUG}/progress.md for current state.
\`\`\`"

echo -e "${BLUE}💬 Adding comment to issue #${ISSUE_NUMBER}...${NC}"
gh issue comment "$ISSUE_NUMBER" --body "$COMMENT_BODY"

echo -e "${GREEN}✅ Added bidirectional link to issue${NC}"

# Summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ DevDocs created successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "📁 Location: ${BLUE}${TASK_DIR}${NC}"
echo -e "📋 Issue:    ${BLUE}${ISSUE_URL}${NC}"
echo ""
echo -e "To start working, tell the agent:"
echo -e "${YELLOW}  Work on issue #${ISSUE_NUMBER}. Read .github/devdocs/issue-${ISSUE_NUMBER}-${ISSUE_SLUG}/plan.md for context.${NC}"
echo ""
