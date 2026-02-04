#!/bin/bash
# bd-init.sh - Initialize Beads in project
# Usage: ./scripts/bd-init.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Beads CLI is installed
if ! command -v bd &> /dev/null; then
    echo -e "${RED}❌ Beads not installed${NC}"
    echo -e "${YELLOW}   Install: npm install -g beads-ai${NC}"
    echo -e "${YELLOW}   Falling back to markdown-only tracking${NC}"
    exit 1
fi

# Check if already initialized
if [ -d ".beads" ]; then
    echo -e "${GREEN}✅ Beads already initialized${NC}"
    exit 0
fi

echo -e "${BLUE}📦 Initializing Beads for devdocs...${NC}"

# Initialize Beads
bd init

# Configure memory decay for session continuity
bd config set memory_decay.enabled true
bd config set memory_decay.threshold 100

echo -e "${GREEN}✅ Beads initialized for devdocs${NC}"
echo -e "${BLUE}   Memory decay: enabled (threshold: 100 tasks)${NC}"
