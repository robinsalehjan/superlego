#!/bin/bash
# bd-from-plan.sh - Parse superpowers plan and create Beads tasks
# Usage: bd-from-plan.sh <plan-file> <epic-id>

set -e

PLAN_FILE=$1
EPIC_ID=$2

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validate arguments
if [ -z "$PLAN_FILE" ] || [ -z "$EPIC_ID" ]; then
    echo -e "${RED}❌ Usage: bd-from-plan.sh <plan-file> <epic-id>${NC}"
    exit 1
fi

# Check if plan file exists
if [ ! -f "$PLAN_FILE" ]; then
    echo -e "${RED}❌ Plan file not found: $PLAN_FILE${NC}"
    exit 1
fi

# Check if Beads is available
if ! command -v bd &> /dev/null; then
    echo -e "${YELLOW}⚠️  Beads not installed - skipping task creation${NC}"
    exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq not installed${NC}"
    echo -e "${YELLOW}   Install: brew install jq${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Parsing plan and creating Beads tasks...${NC}"

# Extract phase titles from markdown (## Phase N: Title or ### Phase N: Title)
# Store in array: phase_titles
declare -a phase_titles
declare -a phase_ids

while IFS= read -r line; do
    # Match lines like "## Phase 1: Title" or "### Phase 1: Title"
    if [[ "$line" =~ ^##[#]?[[:space:]]+Phase[[:space:]]+[0-9]+:[[:space:]]+(.+)$ ]]; then
        phase_title="${BASH_REMATCH[1]}"
        phase_titles+=("$phase_title")
    fi
done < "$PLAN_FILE"

# Check if any phases found
if [ ${#phase_titles[@]} -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No phases found in plan (expected '## Phase N: Title' format)${NC}"
    exit 0
fi

echo -e "${BLUE}   Found ${#phase_titles[@]} phases${NC}"

# Create Beads tasks for each phase with dependencies
PREV_TASK_ID=""

for i in "${!phase_titles[@]}"; do
    phase_num=$((i + 1))
    phase_title="${phase_titles[$i]}"

    # Create task with dependency on previous phase (sequential)
    if [ -n "$PREV_TASK_ID" ]; then
        TASK_ID=$(bd create "Phase $phase_num: $phase_title" --parent "$EPIC_ID" --depends "$PREV_TASK_ID" --json | jq -r '.id')
    else
        TASK_ID=$(bd create "Phase $phase_num: $phase_title" --parent "$EPIC_ID" --json | jq -r '.id')
    fi

    # Validate task creation succeeded
    if [ -z "$TASK_ID" ] || [ "$TASK_ID" = "null" ]; then
        echo -e "${RED}❌ Failed to create task for Phase $phase_num: $phase_title${NC}"
        exit 1
    fi

    phase_ids+=("$TASK_ID")
    PREV_TASK_ID="$TASK_ID"

    echo -e "${GREEN}   ✅ Created $TASK_ID: Phase $phase_num: $phase_title${NC}"
done

echo -e "${GREEN}✅ Created ${#phase_ids[@]} Beads tasks from plan${NC}"

# Output task IDs as JSON for further processing
jq -n --argjson ids "$(printf '%s\n' "${phase_ids[@]}" | jq -R . | jq -s .)" '{task_ids: $ids}'
