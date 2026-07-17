#!/bin/zsh

# ============================================
#  sereno — uninstaller
# ============================================

INSTALL_DIR="$HOME/.config/sereno"
ZSHRC="$HOME/.zshrc"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo "${GREEN}✓${NC} $1" }
warn() { echo "${YELLOW}⚠${NC} $1" }
info() { echo "${CYAN}→${NC} $1" }

echo ""
echo "${BOLD}    ✦ sereno uninstaller ✦${NC}"
echo ""

# ---------- confirmation ----------
echo -n "This will remove sereno from your system. Continue? [y/N] "
read -r REPLY
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""

# ---------- remove installed files ----------
if [[ -d "$INSTALL_DIR" ]]; then
    info "Removing $INSTALL_DIR..."
    rm -rf "$INSTALL_DIR"
    ok "Removed $INSTALL_DIR"
else
    warn "$INSTALL_DIR not found — skipping"
fi

# ---------- remove shell integration ----------
if [[ -f "$ZSHRC" ]]; then
    CLEANED=0
    for marker in "# sereno" "# pokefetch"; do
        if grep -q "^$marker$" "$ZSHRC"; then
            info "Cleaning up ~/.zshrc ($marker)..."
            # Remove the block (marker + next 2 lines)
            sed -i '' "/^$marker\$/,+2d" "$ZSHRC"
            CLEANED=1
        fi
    done
    if [[ "$CLEANED" == "1" ]]; then
        # Remove any trailing blank line left behind
        sed -i '' -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$ZSHRC"
        ok "Shell integration removed"
    else
        ok "No sereno entries in ~/.zshrc"
    fi
fi

echo ""
echo "${GREEN}${BOLD}    ✓ sereno uninstalled${NC}"
echo ""
echo "    Dependencies (fastfetch, ImageMagick, Pillow) were NOT removed."
echo "    Remove them manually with: ${BOLD}brew uninstall fastfetch imagemagick${NC}"
echo ""
