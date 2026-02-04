#!/bin/bash
# bd-parallel-tasks.sh - Find ready tasks for parallel agent dispatch
# Usage: bd-parallel-tasks.sh <epic-id> [--json]

set -e

EPIC_ID=$1
OUTPUT_FORMAT=$2

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validate arguments
if [ -z "$EPIC_ID" ]; then
    echo -e "${RED}❌ Usage: bd-parallel-tasks.sh <epic-id> [--json]${NC}"
    exit 1
fi

# Check if Beads is available
if ! command -v bd &> /dev/null; then
    echo -e "${RED}❌ Beads not installed${NC}"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq not installed${NC}"
    echo -e "${YELLOW}   Install: brew install jq${NC}"
    exit 1
fi

# Get ready tasks (no blocking dependencies)
READY_TASKS=$(bd ready --parent "$EPIC_ID" --json 2>/dev/null) || {
    echo -e "${RED}❌ Failed to query ready tasks for epic $EPIC_ID${NC}"
    exit 1
}

# Validate JSON response
if ! echo "$READY_TASKS" | jq empty &>/dev/null; then
    echo -e "${RED}❌ Invalid JSON response from Beads${NC}"
    exit 1
fi

# Check if output format is JSON
if [ "$OUTPUT_FORMAT" = "--json" ]; then
    # Output raw JSON
    echo "$READY_TASKS"
else
    # Human-readable format
    TASK_COUNT=$(echo "$READY_TASKS" | jq 'length')

    # Validate task count
    if [ -z "$TASK_COUNT" ] || [ "$TASK_COUNT" = "null" ]; then
        echo -e "${RED}❌ Failed to get task count${NC}"
        exit 1
    fi
    if ! [[ "$TASK_COUNT" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}❌ Invalid task count: $TASK_COUNT${NC}"
        exit 1
    fi

    if [ "$TASK_COUNT" -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No ready tasks for epic $EPIC_ID${NC}"
        echo -e "${BLUE}   All tasks either blocked or completed${NC}"
    else
        echo -e "${GREEN}✅ $TASK_COUNT tasks ready for parallel execution:${NC}"
        echo ""
        echo "$READY_TASKS" | jq -r '.[] | "  - \(.id): \(.title)"'
        echo ""
        echo -e "${BLUE}💡 Tip: Use superpowers:dispatching-parallel-agents to execute${NC}"
    fi
fi
