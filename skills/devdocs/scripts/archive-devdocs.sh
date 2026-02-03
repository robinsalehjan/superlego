#!/bin/bash
# archive-devdocs.sh - Archive completed devdocs task
#
# Usage:
#   ./scripts/archive-devdocs.sh <task-directory-name>
#   ./scripts/archive-devdocs.sh issue-123-feature-name
#
# This script automates the completion checklist:
#   1. Creates archive summary from plan.md and progress.md
#   2. Adds entry to archive/INDEX.md
#   3. Optionally deletes the working devdocs directory
#   4. Adds comment to linked GitHub issue (if applicable)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Unified sed helper for cross-platform compatibility
sed_inplace() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Default values
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options] <task-directory-name>"
            echo ""
            echo "Options:"
            echo "  -d, --dry-run    Show what would be done without making changes"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Example: $0 issue-123-feature-name"
            exit 0
            ;;
        -*)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo "Run '$0 --help' for usage"
            exit 1
            ;;
        *)
            TASK_NAME="$1"
            shift
            ;;
    esac
done

# Check arguments
if [ -z "$TASK_NAME" ]; then
    echo -e "${RED}❌ Usage: $0 <task-directory-name>${NC}"
    echo "   Example: $0 issue-123-feature-name"
    echo ""
    echo "Available tasks:"
    ls -d .github/devdocs/*/ 2>/dev/null | grep -v -E "(templates|archive)" | xargs -I {} basename {} || echo "   No active tasks found"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DEVDOCS_DIR="$REPO_ROOT/devdocs"
TASK_DIR="$DEVDOCS_DIR/$TASK_NAME"
ARCHIVE_DIR="$DEVDOCS_DIR/archive"
ARCHIVE_FILE="$ARCHIVE_DIR/$TASK_NAME.md"
INDEX_FILE="$ARCHIVE_DIR/INDEX.md"

# Validation function for devdocs structure
validate_devdocs_structure() {
    local warnings=0

    if ! grep -q "^## Goal" "$PLAN_FILE" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  No '## Goal' section found in plan.md${NC}"
        warnings=$((warnings + 1))
    fi

    if ! grep -q "^## Decisions Made" "$PROGRESS_FILE" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  No '## Decisions Made' section found in progress.md${NC}"
        warnings=$((warnings + 1))
    fi

    if ! grep -q "^## Files Changed" "$PROGRESS_FILE" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  No '## Files Changed' section found in progress.md${NC}"
        warnings=$((warnings + 1))
    fi

    if [ $warnings -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Found $warnings structural warnings. Archive will use defaults for missing sections.${NC}"
    fi

    return 0  # Don't fail, just warn
}

# Validate task exists
if [ ! -d "$TASK_DIR" ]; then
    echo -e "${RED}❌ Task directory not found: $TASK_DIR${NC}"
    echo ""
    echo "Available tasks:"
    ls -d "$DEVDOCS_DIR"/*/ 2>/dev/null | grep -v -E "(templates|archive)" | xargs -I {} basename {} || echo "   No active tasks found"
    exit 1
fi

# Check for plan.md and progress.md
PLAN_FILE="$TASK_DIR/plan.md"
PROGRESS_FILE="$TASK_DIR/progress.md"

if [ ! -f "$PLAN_FILE" ] || [ ! -f "$PROGRESS_FILE" ]; then
    echo -e "${RED}❌ Missing plan.md or progress.md in $TASK_DIR${NC}"
    exit 1
fi

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 DRY RUN - No changes will be made${NC}"
fi

echo -e "${BLUE}📋 Archiving: $TASK_NAME${NC}"

# Validate devdocs structure
validate_devdocs_structure

# Extract information from plan.md
TASK_TITLE=$(grep -m1 "^# " "$PLAN_FILE" | sed 's/^# //' | sed 's/ - Plan$//' || echo "$TASK_NAME")
ISSUE_NUMBER=$(grep -oE "Issue.*#([0-9]+)" "$PLAN_FILE" | grep -oE "[0-9]+" | head -1 || echo "")
ISSUE_URL=$(grep -oE "https://github.com/[^)]*issues/[0-9]+" "$PLAN_FILE" | head -1 || echo "")

# Extract goal from plan.md with fallback
GOAL=$(awk '/^## Goal/,/^##/{if(!/^##/) print}' "$PLAN_FILE" 2>/dev/null | sed '/^$/d' | head -5 | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ //' | sed 's/ $//' | cut -c1-200)
if [ -z "$GOAL" ] || [ "$GOAL" = " " ]; then
    GOAL="See archived devdocs for details."
fi

# Extract key decisions from progress.md with validation
DECISIONS=$(awk '/^## Decisions Made/,/^## /{print}' "$PROGRESS_FILE" 2>/dev/null | grep "^|" | grep -v "Decision\|Rationale\|---" | head -5)
if [ -z "$DECISIONS" ]; then
    DECISIONS="| No decisions recorded | — |"
fi

# Extract files changed from progress.md with fallback
FILES=$(awk '/^## Files Changed/,/^## /{print}' "$PROGRESS_FILE" 2>/dev/null | grep -E "^- " | head -10)
if [ -z "$FILES" ]; then
    FILES="- (See git history for this task)"
fi

# Prompt for tags
echo -ne "${CYAN}Enter tags (comma-separated, e.g., feature, auth, api):${NC} "
read -r TAGS
if [ -z "$TAGS" ]; then
    TAGS="untagged"
fi

# Prompt for key gotchas
echo -ne "${CYAN}Key gotcha/lesson learned (one line):${NC} "
read -r GOTCHA
if [ -z "$GOTCHA" ]; then
    GOTCHA="—"
fi

# Current date
TODAY=$(date +%Y-%m-%d)
MONTH=$(date +%Y-%m)

# Create archive file
echo -e "${BLUE}📝 Creating archive summary...${NC}"

if [ "$DRY_RUN" = true ]; then
    echo -e "${CYAN}Would create: $ARCHIVE_FILE${NC}"
    ARCHIVE_FILE="/dev/stdout"
    echo ""
    echo "--- Archive Preview ---"
fi

if [ "$DRY_RUN" = false ]; then
    cat > "$ARCHIVE_FILE" << EOF
# $TASK_TITLE - Summary

**Completed:** $MONTH
**Tags:** \`$(echo "$TAGS" | sed 's/,/\`, \`/g')\`
**Archived From:** \`devdocs/$TASK_NAME/\`
EOF
else
    cat << EOF
# $TASK_TITLE - Summary

EOF
fi

# Add issue link if exists
if [ -n "$ISSUE_NUMBER" ]; then
    if [ "$DRY_RUN" = false ]; then
        echo "**GitHub Issue:** [#$ISSUE_NUMBER]($ISSUE_URL)" >> "$ARCHIVE_FILE"
    else
        echo "**GitHub Issue:** [#$ISSUE_NUMBER]($ISSUE_URL)"
    fi
fi

if [ "$DRY_RUN" = false ]; then
    cat >> "$ARCHIVE_FILE" << EOF

## What Was Built

$GOAL

## Key Decisions

| Decision | Rationale |
|----------|-----------|
EOF
    echo "$DECISIONS" | while read -r line; do
        echo "$line" >> "$ARCHIVE_FILE"
    done

    cat >> "$ARCHIVE_FILE" << EOF

## Files Changed

EOF
    echo "$FILES" >> "$ARCHIVE_FILE"

    cat >> "$ARCHIVE_FILE" << EOF

## Gotchas Discovered

1. **$GOTCHA**

## Lessons for Future Work

- [Add lessons learned here]

EOF
else
    cat << EOF

## What Was Built

$GOAL

## Key Decisions

| Decision | Rationale |
|----------|-----------|
EOF
    echo "$DECISIONS"

    cat << EOF

## Files Changed

EOF
    echo "$FILES"

    cat << EOF

## Gotchas Discovered

1. **$GOTCHA**

## Lessons for Future Work

- [Add lessons learned here]

EOF
    echo "--- End Archive Preview ---"
    echo ""
fi

if [ "$DRY_RUN" = false ]; then
    echo -e "${GREEN}✓ Created $ARCHIVE_FILE${NC}"
else
    echo -e "${CYAN}Would create archive file${NC}"
fi

# Update INDEX.md
echo -e "${BLUE}📑 Updating archive index...${NC}"

# Format tags for the table
TAGS_FORMATTED=$(echo "$TAGS" | sed 's/,/, /g' | sed 's/^/`/' | sed 's/$/ `/g' | sed 's/, /`, `/g')

# Create the new entry
NEW_ENTRY="| [$TASK_NAME]($TASK_NAME.md) | ${ISSUE_NUMBER:+[#$ISSUE_NUMBER]($ISSUE_URL)}${ISSUE_NUMBER:-—} | $MONTH | $TAGS_FORMATTED | $TASK_TITLE | $GOTCHA |"

# Add entry after the header row (find the last | line in the table and append)
if grep -q "^| \[$TASK_NAME\]" "$INDEX_FILE" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Entry already exists in INDEX.md${NC}"
else
    if [ "$DRY_RUN" = false ]; then
        # Find the line number of the comment template and insert before it
        sed_inplace "/^<!-- Template for new entries/i\\
$NEW_ENTRY
" "$INDEX_FILE"

        # Verify the update succeeded
        if ! grep -q "^\| \[$TASK_NAME\]" "$INDEX_FILE" 2>/dev/null; then
            echo -e "${RED}❌ Failed to update INDEX.md${NC}"
            echo -e "${YELLOW}   Please manually add this entry:${NC}"
            echo "$NEW_ENTRY"
            exit 1
        fi
        echo -e "${GREEN}✓ Added entry to INDEX.md${NC}"
    else
        echo -e "${CYAN}Would add to INDEX.md:${NC}"
        echo "$NEW_ENTRY"
    fi
fi

# Add comment to GitHub issue if applicable
if [ -n "$ISSUE_NUMBER" ] && [ "$DRY_RUN" = false ]; then
    if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
        echo -ne "${CYAN}Add completion comment to issue #$ISSUE_NUMBER? (Y/n):${NC} "
        read -r add_comment
        if [[ ! "$add_comment" =~ ^[Nn] ]]; then
            COMMENT="🏁 **DevDocs Archived**

This task has been completed and archived:
- Archive: [\`$ARCHIVE_FILE\`]($ARCHIVE_FILE)

**Summary:** $TASK_TITLE

**Key Gotcha:** $GOTCHA"

            gh issue comment "$ISSUE_NUMBER" --body "$COMMENT"
            echo -e "${GREEN}✓ Added comment to issue #$ISSUE_NUMBER${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  GitHub CLI not available, skipping issue comment${NC}"
    fi
elif [ -n "$ISSUE_NUMBER" ] && [ "$DRY_RUN" = true ]; then
    echo -e "${CYAN}Would add comment to issue #$ISSUE_NUMBER${NC}"
fi

# Prompt to delete working directory
if [ "$DRY_RUN" = false ]; then
    echo ""
    echo -ne "${CYAN}Delete working devdocs directory? (y/N):${NC} "
    read -r delete_dir
    if [[ "$delete_dir" =~ ^[Yy] ]]; then
        rm -rf "$TASK_DIR"
        echo -e "${GREEN}✓ Deleted $TASK_DIR${NC}"
    else
        echo -e "${YELLOW}Working directory preserved at $TASK_DIR${NC}"
    fi
else
    echo -e "${CYAN}Would prompt to delete: $TASK_DIR${NC}"
fi

# Summary
echo ""
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}✅ Dry run complete! No changes made.${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "Run without --dry-run to apply changes."
else
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Archive complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "📁 Archive: ${BLUE}$ARCHIVE_FILE${NC}"
    echo -e "📋 Index:   ${BLUE}$INDEX_FILE${NC}"
    echo ""
    echo -e "${YELLOW}Remaining manual steps:${NC}"
    echo -e "  • Update feature documentation in {{DOCS_PATH}}/features/ (if applicable)"
    echo -e "  • Add implementation history link in feature docs"
    echo -e "  • Review and enhance the archive summary"
fi
echo ""
