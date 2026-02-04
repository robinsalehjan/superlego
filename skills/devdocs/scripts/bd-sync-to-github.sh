#!/bin/bash
# bd-sync-to-github.sh - Sync Beads task completion to GitHub issue
# Usage: bd-sync-to-github.sh <task-id>

set -e

TASK_ID=$1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validate arguments
if [ -z "$TASK_ID" ]; then
    echo -e "${RED}❌ Usage: bd-sync-to-github.sh <task-id>${NC}"
    exit 1
fi

# Check if Beads is available
if ! command -v bd &> /dev/null; then
    echo -e "${YELLOW}⚠️  Beads not installed - skipping GitHub sync${NC}"
    exit 0
fi

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI not installed - skipping sync${NC}"
    exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq not installed${NC}"
    echo -e "${YELLOW}   Install: brew install jq${NC}"
    exit 1
fi

# Get task details
TASK_JSON=$(bd show "$TASK_ID" --json 2>/dev/null) || {
    echo -e "${RED}❌ Task $TASK_ID not found${NC}"
    exit 1
}

TASK_TITLE=$(echo "$TASK_JSON" | jq -r '.title')
TASK_STATUS=$(echo "$TASK_JSON" | jq -r '.status')

# Get parent epic
EPIC_ID=$(echo "$TASK_JSON" | jq -r '.parent // empty')

if [ -z "$EPIC_ID" ]; then
    echo -e "${YELLOW}⚠️  Task $TASK_ID has no parent epic - skipping GitHub sync${NC}"
    exit 0
fi

# Get GitHub issue from epic metadata
EPIC_JSON=$(bd show "$EPIC_ID" --json 2>/dev/null) || {
    echo -e "${RED}❌ Epic $EPIC_ID not found${NC}"
    exit 1
}

GITHUB_ISSUE=$(echo "$EPIC_JSON" | jq -r '.meta.github_issue // empty')

if [ -z "$GITHUB_ISSUE" ]; then
    echo -e "${YELLOW}⚠️  Epic $EPIC_ID has no github_issue metadata - skipping sync${NC}"
    exit 0
fi

# Validate GitHub issue number format
if ! [[ "$GITHUB_ISSUE" =~ ^[0-9]+$ ]]; then
    echo -e "${YELLOW}⚠️  Invalid github_issue format: $GITHUB_ISSUE (expected number)${NC}"
    exit 0
fi

echo -e "${BLUE}🔄 Syncing task $TASK_ID to GitHub issue #$GITHUB_ISSUE...${NC}"

# Sync based on status
if [ "$TASK_STATUS" = "completed" ]; then
    # Post completion comment
    gh issue comment "$GITHUB_ISSUE" --body "✅ Completed: $TASK_TITLE (\`$TASK_ID\`)" 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Failed to post comment to issue #$GITHUB_ISSUE${NC}"
        exit 0
    }

    echo -e "${GREEN}   ✅ Posted completion comment${NC}"

    # Check if all epic tasks complete
    EPIC_STATUS=$(bd status "$EPIC_ID" --json)
    TOTAL=$(echo "$EPIC_STATUS" | jq '.total')
    COMPLETED=$(echo "$EPIC_STATUS" | jq '.completed')

    # Validate epic status data
    if [ -z "$TOTAL" ] || [ -z "$COMPLETED" ]; then
        echo -e "${YELLOW}⚠️  Epic status missing data${NC}"
        exit 0
    fi
    if ! [[ "$TOTAL" =~ ^[0-9]+$ ]] || ! [[ "$COMPLETED" =~ ^[0-9]+$ ]]; then
        echo -e "${YELLOW}⚠️  Epic status contains non-numeric data${NC}"
        exit 0
    fi

    echo -e "${BLUE}   Epic progress: $COMPLETED/$TOTAL tasks complete${NC}"

    if [ "$TOTAL" -eq "$COMPLETED" ]; then
        # Close the issue
        gh issue close "$GITHUB_ISSUE" --comment "🎉 All Beads tasks completed for epic \`$EPIC_ID\`" 2>/dev/null || {
            echo -e "${YELLOW}⚠️  Failed to close issue #$GITHUB_ISSUE${NC}"
            exit 0
        }
        echo -e "${GREEN}   🎉 Closed issue #$GITHUB_ISSUE (all tasks complete)${NC}"
    fi
fi

echo -e "${GREEN}✅ GitHub sync complete${NC}"
