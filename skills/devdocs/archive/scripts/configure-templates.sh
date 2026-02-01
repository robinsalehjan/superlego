#!/bin/bash
# configure-templates.sh - Replace template placeholders with project-specific values
#
# Usage:
#   ./scripts/configure-templates.sh [options]
#
# Options:
#   -c, --config FILE    Path to placeholders config file (default: shared/placeholders.yaml)
#   -d, --dry-run        Show what would be replaced without making changes
#   -v, --verbose        Show detailed output
#   -h, --help           Show this help message
#
# This script reads placeholder values from a YAML config file and replaces
# all {{PLACEHOLDER}} patterns in .md and .sh files throughout the .github directory.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$REPO_ROOT/shared/placeholders.yaml"
DRY_RUN=false
VERBOSE=false
BACKUP=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -b|--backup)
            BACKUP=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -c, --config FILE    Path to placeholders config file (default: shared/placeholders.yaml)"
            echo "  -d, --dry-run        Show what would be replaced without making changes"
            echo "  -v, --verbose        Show detailed output"
            echo "  -b, --backup         Create .bak files before modifying"
            echo "  -h, --help           Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Config file not found: $CONFIG_FILE${NC}"
    echo -e "${YELLOW}   Copy shared/placeholders.yaml.example to shared/placeholders.yaml and fill in your values.${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Reading configuration from: $CONFIG_FILE${NC}"

# Check for yq (YAML parser)
if ! command -v yq &> /dev/null; then
    echo -e "${YELLOW}⚠️  'yq' not found. Using fallback parser (limited YAML support).${NC}"
    echo -e "${YELLOW}   For full YAML support, install yq: brew install yq${NC}"
    USE_YQ=false
else
    USE_YQ=true
fi

# Function to parse YAML (simple key: value format)
parse_yaml() {
    local file="$1"

    if [ "$USE_YQ" = true ]; then
        # Use yq for proper YAML parsing
        yq eval 'to_entries | .[] | select(.value != null) | "\(.key)=\(.value)"' "$file" 2>/dev/null
    else
        # Fallback: simple grep/sed parser (handles basic KEY: "value" format)
        grep -E '^[A-Z_]+:' "$file" | \
            sed 's/#.*//' | \
            sed 's/^[[:space:]]*//' | \
            sed 's/[[:space:]]*$//' | \
            grep -v '^$' | \
            sed 's/: */=/' | \
            sed 's/^//' | \
            sed 's/"//g'
    fi
}

# Read placeholders into associative array
declare -A PLACEHOLDERS
while IFS='=' read -r key value; do
    # Skip empty lines and comments
    [[ -z "$key" || "$key" =~ ^# ]] && continue
    # Trim whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    if [ -n "$key" ] && [ -n "$value" ]; then
        PLACEHOLDERS["$key"]="$value"
        if [ "$VERBOSE" = true ]; then
            echo -e "   ${key} = ${value}"
        fi
    fi
done < <(parse_yaml "$CONFIG_FILE")

PLACEHOLDER_COUNT=${#PLACEHOLDERS[@]}
echo -e "${GREEN}✓ Loaded $PLACEHOLDER_COUNT placeholders${NC}"

if [ "$PLACEHOLDER_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ No placeholders found in config file.${NC}"
    exit 1
fi

# Find all files to process with comprehensive exclusions
FILES=$(find "$REPO_ROOT" \( -name "*.md" -o -name "*.sh" \) -type f \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/dist/*" \
    ! -path "*/build/*" \
    ! -path "*/.next/*" \
    ! -path "*/target/*" \
    ! -path "*/.venv/*" \
    ! -path "*/venv/*" \
    ! -path "*/__pycache__/*" \
    ! -path "*/.pytest_cache/*" \
    2>/dev/null || true)
FILE_COUNT=$(echo "$FILES" | grep -c . || echo 0)

echo -e "${BLUE}📁 Found $FILE_COUNT files to process${NC}"

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 DRY RUN - No changes will be made${NC}"
fi

if [ "$BACKUP" = true ]; then
    echo -e "${BLUE}💾 Backup mode enabled - .bak files will be created${NC}"
fi

# Process each file
TOTAL_REPLACEMENTS=0
MODIFIED_FILES=0

for file in $FILES; do
    FILE_CHANGES=0

    # Create backup if requested
    if [ "$BACKUP" = true ] && [ "$DRY_RUN" = false ]; then
        if [ ! -f "${file}.bak" ]; then
            cp "$file" "${file}.bak"
        fi
    fi

    for key in "${!PLACEHOLDERS[@]}"; do
        value="${PLACEHOLDERS[$key]}"
        pattern="\{\{${key}\}\}"

        # Count occurrences - more robust approach
        count=$(grep -o "$pattern" "$file" 2>/dev/null | wc -l | tr -d ' ')

        if [ "$count" -gt 0 ]; then
            if [ "$VERBOSE" = true ]; then
                echo -e "   ${file}: {{${key}}} → ${value} (${count}x)"
            fi

            if [ "$DRY_RUN" = false ]; then
                # Escape special characters in value for sed
                escaped_value=$(printf '%s\n' "$value" | sed 's/[&/\]/\\&/g')
                # Use unified sed helper
                sed_inplace "s/${pattern}/${escaped_value}/g" "$file"
            fi

            FILE_CHANGES=$((FILE_CHANGES + count))
        fi
    done

    if [ "$FILE_CHANGES" -gt 0 ]; then
        MODIFIED_FILES=$((MODIFIED_FILES + 1))
        TOTAL_REPLACEMENTS=$((TOTAL_REPLACEMENTS + FILE_CHANGES))

        if [ "$VERBOSE" = false ] && [ "$DRY_RUN" = false ]; then
            echo -e "   ${GREEN}✓${NC} $(basename "$file"): $FILE_CHANGES replacements"
        fi
    fi
done

echo ""
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}📊 Would make $TOTAL_REPLACEMENTS replacements in $MODIFIED_FILES files${NC}"
    echo -e "${YELLOW}   Run without --dry-run to apply changes.${NC}"
else
    echo -e "${GREEN}✅ Complete! Made $TOTAL_REPLACEMENTS replacements in $MODIFIED_FILES files${NC}"
fi

# Check for remaining placeholders
REMAINING=$(grep -roh '\{\{[A-Z0-9_]*\}\}' "$REPO_ROOT" --include="*.md" --include="*.sh" 2>/dev/null | sort -u || true)
if [ -n "$REMAINING" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Remaining placeholders (not in config):${NC}"
    echo "$REMAINING" | while read -r placeholder; do
        echo -e "   ${YELLOW}$placeholder${NC}"
    done
    echo -e "${YELLOW}   Add these to your config file if needed.${NC}"
fi
