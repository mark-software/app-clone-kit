#!/bin/bash

# ============================================================================
# app-clone-kit installer
# Copies phase files and slash commands into target project.
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Determine where the templates live (relative to this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

# Determine target
GLOBAL=false
SKIP_MCP=false
TARGET_DIR="$(pwd)"

for arg in "$@"; do
    case "$arg" in
        --global|-g)
            GLOBAL=true
            ;;
        --skip-mcp)
            SKIP_MCP=true
            ;;
        --help|-h)
            echo ""
            echo "  app-clone-kit install"
            echo ""
            echo "  Usage:"
            echo "    ./bin/install.sh              Install into current project"
            echo "    ./bin/install.sh --global     Install /clone command globally"
            echo "    ./bin/install.sh --skip-mcp    Skip Mobile MCP auto-install"
            echo ""
            echo "  Remote install:"
            echo "    curl -fsSL https://raw.githubusercontent.com/mark-software/app-clone-kit/main/bin/remote-install.sh | bash"
            echo ""
            exit 0
            ;;
    esac
done

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  app-clone-kit${NC} ${DIM}installer${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ---- Validate templates exist ----
if [ ! -d "$TEMPLATE_DIR/phases" ]; then
    echo -e "${RED}  Error: Template files not found at $TEMPLATE_DIR${NC}"
    echo -e "${DIM}  This usually means the package wasn't installed correctly.${NC}"
    exit 1
fi

# ---- Install slash command ----
if [ "$GLOBAL" = true ]; then
    CMD_DIR="$HOME/.claude/commands"
else
    CMD_DIR="$TARGET_DIR/.claude/commands"
fi

mkdir -p "$CMD_DIR"
cp "$TEMPLATE_DIR/commands/research-app.md" "$CMD_DIR/research-app.md"
cp "$TEMPLATE_DIR/commands/build-app.md" "$CMD_DIR/build-app.md"
echo -e "${GREEN}  ✓${NC} Installed /research-app and /build-app commands to ${DIM}$CMD_DIR/${NC}"

# ---- Install phase files ----
CLONE_KIT_DIR="$TARGET_DIR/.clone-kit"
mkdir -p "$CLONE_KIT_DIR/phases"

# Copy research/planning phases (active)
for phase_file in "$TEMPLATE_DIR/phases/"{01,02,03}*.md; do
    [ -f "$phase_file" ] && cp "$phase_file" "$CLONE_KIT_DIR/phases/$(basename "$phase_file")"
done

# Copy consolidated build instructions (active)
cp "$TEMPLATE_DIR/phases/build.md" "$CLONE_KIT_DIR/phases/build.md"

# Copy old build phases as reference
for phase_file in "$TEMPLATE_DIR/phases/"{04,05,06}*.md; do
    [ -f "$phase_file" ] || continue
    filename=$(basename "$phase_file")
    refname="${filename%.md}.ref.md"
    cp "$phase_file" "$CLONE_KIT_DIR/phases/$refname"
done
echo -e "${GREEN}  ✓${NC} Installed phase files to ${DIM}.clone-kit/phases/${NC}"

# ---- Install skills ----
if [ -d "$TEMPLATE_DIR/skills" ]; then
    SKILLS_DIR="$TARGET_DIR/.claude/skills"
    for skill_dir in "$TEMPLATE_DIR/skills/"*/; do
        skill_name=$(basename "$skill_dir")
        mkdir -p "$SKILLS_DIR/$skill_name"
        cp "$skill_dir"* "$SKILLS_DIR/$skill_name/" 2>/dev/null || true
    done
    echo -e "${GREEN}  ✓${NC} Installed skills to ${DIM}.claude/skills/${NC}"
fi

# ---- Add to .gitignore ----
GITIGNORE="$TARGET_DIR/.gitignore"
ENTRIES=(
    "progress.json"
    "test-results.json"
    "research/"
    "analysis/"
    "screenshots/"
    ".session-logs/"
    "decompiled/"
    "docs/qa/"
)

if [ -f "$GITIGNORE" ]; then
    for entry in "${ENTRIES[@]}"; do
        if ! grep -qF "$entry" "$GITIGNORE" 2>/dev/null; then
            echo "$entry" >> "$GITIGNORE"
        fi
    done
    echo -e "${GREEN}  ✓${NC} Updated .gitignore"
else
    printf '%s\n' "${ENTRIES[@]}" > "$GITIGNORE"
    echo -e "${GREEN}  ✓${NC} Created .gitignore"
fi

# ---- Check for prerequisites ----
echo ""
echo -e "${BOLD}  Prerequisites:${NC}"

if command -v claude &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Claude Code"
else
    echo -e "  ${YELLOW}!${NC} Claude Code not found - install: ${DIM}npm install -g @anthropic-ai/claude-code${NC}"
fi

if command -v jadx &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} jadx (APK decompilation)"
else
    echo -e "  ${DIM}○${NC} jadx not found (optional) - install: ${DIM}brew install jadx${NC}"
fi

# Install mobile MCP
if command -v claude &>/dev/null && claude mcp list 2>/dev/null | grep -qi "mobile"; then
    echo -e "  ${GREEN}✓${NC} Mobile MCP"
elif ! command -v claude &>/dev/null; then
    echo -e "  ${DIM}○${NC} Mobile MCP (skipped - claude CLI not available)"
elif [ "$SKIP_MCP" = true ]; then
    echo -e "  ${DIM}○${NC} Mobile MCP (skipped)"
else
    echo -e "  ${DIM}  Installing mobile-mcp...${NC}"
    if claude mcp add mobile-mcp -- npx -y @mobilenext/mobile-mcp@latest 2>&1; then
        echo -e "  ${GREEN}✓${NC} Mobile MCP installed"
    else
        echo -e "  ${RED}✗${NC} Mobile MCP install failed"
        echo -e "    ${DIM}You can install manually: claude mcp add mobile-mcp -- npx -y @mobilenext/mobile-mcp@latest${NC}"
    fi
fi

# ---- Done ----
echo ""
echo -e "${GREEN}  Done!${NC} Start cloning:"
echo ""
echo -e "    ${BOLD}claude${NC}"
echo -e "    ${BOLD}> /research-app ${DIM}<app name>${NC}"
echo -e "    ${DIM}Then: /build-app${NC}"
echo ""
