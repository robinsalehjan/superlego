#!/bin/bash
# init-project.sh - Interactive setup script for new projects using this template
#
# Usage:
#   ./scripts/init-project.sh
#
# This script:
#   1. Prompts for project configuration values
#   2. Updates placeholders.yaml
#   3. Runs configure-templates.sh
#   4. Creates project directory structure
#   5. Cleans up example files
#   6. Initializes git (if not already initialized)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Unified sed helper for cross-platform compatibility
sed_inplace() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Script directory and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$REPO_ROOT/shared/placeholders.yaml"

echo ""
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${BLUE}   🚀 Project Initialization Wizard${NC}"
echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}This wizard will configure your project by setting up placeholders${NC}"
echo -e "${CYAN}and creating the necessary directory structure.${NC}"
echo ""

# Function to prompt with default value
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"

    echo -ne "${BOLD}${prompt}${NC} [${default}]: "
    read -r input
    if [ -z "$input" ]; then
        eval "$var_name=\"$default\""
    else
        eval "$var_name=\"$input\""
    fi
}

# Function to prompt required value
prompt_required() {
    local prompt="$1"
    local var_name="$2"

    while true; do
        echo -ne "${BOLD}${prompt}${NC}: "
        read -r input
        if [ -n "$input" ]; then
            eval "$var_name=\"$input\""
            break
        else
            echo -e "${RED}This field is required.${NC}"
        fi
    done
}

# Function to prompt with options
prompt_options() {
    local prompt="$1"
    local options="$2"
    local default="$3"
    local var_name="$4"

    echo -e "${BOLD}${prompt}${NC}"
    echo -e "  ${CYAN}Options: ${options}${NC}"
    echo -ne "  Choice [${default}]: "
    read -r input
    if [ -z "$input" ]; then
        eval "$var_name=\"$default\""
    else
        eval "$var_name=\"$input\""
    fi
}

echo -e "${YELLOW}─── PROJECT INFO ───${NC}"
echo ""

prompt_required "Project name" PROJECT_NAME
prompt_options "Role specialty" "iOS, Frontend, Backend, Full Stack, DevOps, Mobile" "Full Stack" ROLE_SPECIALTY

echo ""
echo -e "${YELLOW}─── TECH STACK ───${NC}"
echo ""

prompt_options "Language & version" "Swift 6, TypeScript 5.0, Python 3.12, Go 1.21, Rust 1.75" "TypeScript 5.0" LANGUAGE_VERSION
prompt_options "Frontend framework" "React, Vue, Angular, SwiftUI, Jetpack Compose, None" "React" FRONTEND_FRAMEWORK
prompt_options "Backend framework" "Node.js, Django, FastAPI, Vapor, Spring Boot, None" "Node.js" BACKEND_FRAMEWORK
prompt_options "Platform" "Web, iOS, Android, Desktop, CLI, Multi-platform" "Web" PLATFORM

echo ""
echo -e "${YELLOW}─── PATHS ───${NC}"
echo ""

prompt_with_default "Source code path" "src/" SRC_PATH
prompt_with_default "Tests path" "tests/" TESTS_PATH
prompt_with_default "Documentation path" "docs/" DOCS_PATH

echo ""
echo -e "${YELLOW}─── COMMANDS ───${NC}"
echo ""

# Set smart defaults based on language/platform
if [[ "$LANGUAGE_VERSION" == *"TypeScript"* ]] || [[ "$LANGUAGE_VERSION" == *"JavaScript"* ]]; then
    DEFAULT_BUILD="npm run build"
    DEFAULT_TEST="npm test"
    DEFAULT_LINTER="eslint"
    DEFAULT_CLEAN="npm run clean"
    DEFAULT_DEV="npm run dev"
    DEFAULT_PKG="npm"
elif [[ "$LANGUAGE_VERSION" == *"Python"* ]]; then
    DEFAULT_BUILD="python -m build"
    DEFAULT_TEST="pytest"
    DEFAULT_LINTER="ruff"
    DEFAULT_CLEAN="rm -rf dist build *.egg-info"
    DEFAULT_DEV="python -m uvicorn main:app --reload"
    DEFAULT_PKG="pip"
elif [[ "$LANGUAGE_VERSION" == *"Swift"* ]]; then
    DEFAULT_BUILD="swift build"
    DEFAULT_TEST="swift test"
    DEFAULT_LINTER="swiftlint"
    DEFAULT_CLEAN="swift package clean"
    DEFAULT_DEV="swift run"
    DEFAULT_PKG="spm"
elif [[ "$LANGUAGE_VERSION" == *"Go"* ]]; then
    DEFAULT_BUILD="go build ./..."
    DEFAULT_TEST="go test ./..."
    DEFAULT_LINTER="golangci-lint run"
    DEFAULT_CLEAN="go clean"
    DEFAULT_DEV="go run ."
    DEFAULT_PKG="go"
else
    DEFAULT_BUILD="make build"
    DEFAULT_TEST="make test"
    DEFAULT_LINTER="make lint"
    DEFAULT_CLEAN="make clean"
    DEFAULT_DEV="make dev"
    DEFAULT_PKG="make"
fi

prompt_with_default "Build command" "$DEFAULT_BUILD" BUILD_CMD
prompt_with_default "Test command" "$DEFAULT_TEST" TEST_CMD
prompt_with_default "Linter" "$DEFAULT_LINTER" LINTER
prompt_with_default "Clean command" "$DEFAULT_CLEAN" CLEAN_CMD
prompt_with_default "Dev server command" "$DEFAULT_DEV" DEV_SERVER_CMD
prompt_with_default "Package manager" "$DEFAULT_PKG" PACKAGE_MANAGER

echo ""
echo -e "${YELLOW}─── REPOSITORY ───${NC}"
echo ""

# Try to detect from git remote
DETECTED_OWNER=""
DETECTED_REPO=""
if command -v git &> /dev/null && git remote get-url origin &> /dev/null; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
        DETECTED_OWNER="${BASH_REMATCH[1]}"
        DETECTED_REPO="${BASH_REMATCH[2]}"
    fi
fi

prompt_with_default "GitHub username/org" "${DETECTED_OWNER:-username}" REPO_OWNER
prompt_with_default "Repository name" "${DETECTED_REPO:-$PROJECT_NAME}" REPO_NAME

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Configuration Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}Project:${NC} $PROJECT_NAME"
echo -e "  ${BOLD}Role:${NC} $ROLE_SPECIALTY"
echo -e "  ${BOLD}Stack:${NC} $LANGUAGE_VERSION / $FRONTEND_FRAMEWORK / $BACKEND_FRAMEWORK"
echo -e "  ${BOLD}Platform:${NC} $PLATFORM"
echo -e "  ${BOLD}Paths:${NC} $SRC_PATH | $TESTS_PATH | $DOCS_PATH"
echo -e "  ${BOLD}Repo:${NC} $REPO_OWNER/$REPO_NAME"
echo ""

echo -ne "${BOLD}Proceed with this configuration? (Y/n):${NC} "
read -r confirm
if [[ "$confirm" =~ ^[Nn] ]]; then
    echo -e "${YELLOW}Aborted. Run again to reconfigure.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}📝 Writing configuration...${NC}"

# Write placeholders.yaml
cat > "$CONFIG_FILE" << EOF
# Template Placeholders Configuration
# -----------------------------------
# Generated by init-project.sh on $(date +%Y-%m-%d)
# Run: ./scripts/configure-templates.sh
#
# Only core placeholders are included. Add custom placeholders as needed.

# =============================================================================
# PROJECT
# =============================================================================

PROJECT_NAME: "$PROJECT_NAME"
ROLE_SPECIALTY: "$ROLE_SPECIALTY"

# =============================================================================
# STACK
# =============================================================================

LANGUAGE_VERSION: "$LANGUAGE_VERSION"
FRONTEND_FRAMEWORK: "$FRONTEND_FRAMEWORK"
BACKEND_FRAMEWORK: "$BACKEND_FRAMEWORK"
PLATFORM: "$PLATFORM"

# =============================================================================
# PATHS
# =============================================================================

SRC_PATH: "$SRC_PATH"
TESTS_PATH: "$TESTS_PATH"
DOCS_PATH: "$DOCS_PATH"

# =============================================================================
# COMMANDS
# =============================================================================

BUILD_CMD: "$BUILD_CMD"
TEST_CMD: "$TEST_CMD"
LINTER: "$LINTER"
CLEAN_CMD: "$CLEAN_CMD"
DEV_SERVER_CMD: "$DEV_SERVER_CMD"
PACKAGE_MANAGER: "$PACKAGE_MANAGER"

# =============================================================================
# REPOSITORY (for generated links and templates)
# =============================================================================

REPO_OWNER: "$REPO_OWNER"
REPO_NAME: "$REPO_NAME"
EOF

echo -e "${GREEN}✓ Configuration saved to shared/placeholders.yaml${NC}"

# Create project directories and copy templates BEFORE running configure
echo ""
echo -e "${BLUE}📁 Creating project structure...${NC}"

# Better project root detection
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$PROJECT_ROOT" ]; then
    PROJECT_ROOT="$(cd "$REPO_ROOT/.." && pwd)"
fi

# Create docs/features directory
FEATURES_DIR="$PROJECT_ROOT/$DOCS_PATH/features"
mkdir -p "$FEATURES_DIR"
echo -e "${GREEN}✓ Created $DOCS_PATH/features/${NC}"

# Copy feature templates to the project's docs folder
if [ -d "$REPO_ROOT/shared/templates/feature" ]; then
    mkdir -p "$FEATURES_DIR/_templates"
    cp -r "$REPO_ROOT/shared/templates/feature/"* "$FEATURES_DIR/_templates/"
    echo -e "${GREEN}✓ Copied feature templates to $DOCS_PATH/features/_templates/${NC}"
fi

# Create src and tests directories
mkdir -p "$PROJECT_ROOT/$SRC_PATH"
mkdir -p "$PROJECT_ROOT/$TESTS_PATH"
echo -e "${GREEN}✓ Created $SRC_PATH and $TESTS_PATH directories${NC}"

# Run configure-templates.sh AFTER copying templates
echo ""
echo -e "${BLUE}🔄 Applying templates...${NC}"
"$SCRIPT_DIR/configure-templates.sh"

# Clean up example files (optional)
echo ""
echo -ne "${BOLD}Remove example archive file? (y/N):${NC} "
read -r remove_examples
if [[ "$remove_examples" =~ ^[Yy] ]]; then
    rm -f "$REPO_ROOT/devdocs/archive/example-feature-v2-migration.md"
    echo -e "${GREEN}✓ Removed example archive file${NC}"

    # Update INDEX.md to remove example entry
    if [ -f "$REPO_ROOT/devdocs/archive/INDEX.md" ]; then
        sed_inplace '/example-feature-v2-migration/d' "$REPO_ROOT/devdocs/archive/INDEX.md"
        echo -e "${GREEN}✓ Updated archive INDEX.md${NC}"
    fi
fi

# Final summary
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Project initialized successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo -e "  1. Review ${CYAN}AGENTS.md${NC} - customized for your project"
echo -e "  2. Review ${CYAN}.github/devdocs/DEBUGGING.md${NC} - add project-specific patterns"
echo -e "  3. Create a feature: ${CYAN}cp shared/templates/feature/* $DOCS_PATH/features/MyFeature/${NC}"
echo -e "  4. Start a task: ${CYAN}./scripts/devdocs-create.sh --new --title \"My Task\"${NC}"
echo ""
echo -e "${CYAN}Happy coding! 🎉${NC}"
echo ""
