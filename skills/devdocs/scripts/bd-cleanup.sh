#!/bin/bash
# bd-cleanup.sh - Archive/cleanup Beads tasks when devdocs archived
# Usage: bd-cleanup.sh <epic-id>

set -e

EPIC_ID=$1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Validate arguments
if [ -z "$EPIC_ID" ]; then
    echo -e "${RED}❌ Usage: bd-cleanup.sh <epic-id>${NC}"
    exit 1
fi

# Validate epic ID format (alphanumeric, hyphens, underscores)
if ! [[ "$EPIC_ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${RED}❌ Invalid epic ID format: $EPIC_ID${NC}"
    echo -e "${YELLOW}   Expected: alphanumeric characters, hyphens, or underscores${NC}"
    exit 1
fi

# Check if Beads is available
if ! command -v bd &> /dev/null; then
    echo -e "${YELLOW}⚠️  Beads not installed - skipping cleanup${NC}"
    exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ jq is required but not installed${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Archiving Beads epic $EPIC_ID...${NC}"

# Get epic status
EPIC_STATUS=$(bd status "$EPIC_ID" --json 2>/dev/null) || {
    echo -e "${YELLOW}⚠️  Epic $EPIC_ID not found - may already be archived${NC}"
    exit 0
}

# Validate JSON structure before extracting fields
if ! echo "$EPIC_STATUS" | jq -e '.total, .completed' &>/dev/null; then
    echo -e "${RED}❌ Invalid response from Beads - missing required fields${NC}"
    exit 1
fi

TOTAL=$(echo "$EPIC_STATUS" | jq -r '.total // empty')
COMPLETED=$(echo "$EPIC_STATUS" | jq -r '.completed // empty')

# Validate numeric data (empty string check catches null/empty responses)
if [ -z "$TOTAL" ] || [ -z "$COMPLETED" ]; then
    echo -e "${RED}❌ Missing task counts from Beads response${NC}"
    exit 1
fi

if ! [[ "$TOTAL" =~ ^[0-9]+$ ]] || ! [[ "$COMPLETED" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}❌ Invalid task counts: total=$TOTAL, completed=$COMPLETED${NC}"
    exit 1
fi

echo -e "${BLUE}   Final status: $COMPLETED/$TOTAL tasks complete${NC}"

# Close epic with summary
SUMMARY="Epic completed with $COMPLETED/$TOTAL tasks finished. Archived by devdocs."
bd close "$EPIC_ID" --summary "$SUMMARY" 2>/dev/null || {
    echo -e "${YELLOW}⚠️  Failed to close epic - it may already be closed${NC}"
}

echo -e "${GREEN}✅ Beads epic archived${NC}"
echo -e "${BLUE}   Summary: $SUMMARY${NC}"

# Output completion stats for archive
jq -n \
    --arg epic_id "$EPIC_ID" \
    --argjson total "$TOTAL" \
    --argjson completed "$COMPLETED" \
    '{epic_id: $epic_id, total: $total, completed: $completed}'
