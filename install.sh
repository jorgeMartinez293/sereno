#!/bin/zsh

# ============================================
#  sereno — installer
# ============================================

set -e

SCRIPT_DIR="${0:A:h}"
INSTALL_DIR="$HOME/.config/sereno"
SPRITES_DIR="$INSTALL_DIR/sprites"

# Old pokefetch install location (pre-rename), migrated below.
LEGACY_DIR="$HOME/.config/fastfetch"

# ---------- colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo "${GREEN}✓${NC} $1" }
warn() { echo "${YELLOW}⚠${NC} $1" }
err()  { echo "${RED}✗${NC} $1" }
info() { echo "${CYAN}→${NC} $1" }

# ---------- banner ----------
echo ""
echo "${BOLD}    ✦ sereno installer ✦${NC}"
echo "    Animated sprites with your system info, every time you open the terminal"
echo ""

# ---------- check macOS ----------
if [[ "$(uname)" != "Darwin" ]]; then
    err "sereno currently only supports macOS."
    exit 1
fi

# ---------- check / install Homebrew ----------
if ! command -v brew &> /dev/null; then
    warn "Homebrew is not installed."
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
ok "Homebrew"

# ---------- check / install fastfetch ----------
if ! command -v fastfetch &> /dev/null; then
    info "Installing fastfetch..."
    brew install fastfetch
fi
ok "fastfetch $(fastfetch --version 2>/dev/null | head -n1)"

# ---------- check / install ImageMagick ----------
if ! command -v magick &> /dev/null; then
    info "Installing ImageMagick..."
    brew install imagemagick
fi
ok "ImageMagick"

# ---------- check / install Python 3 ----------
if ! command -v python3 &> /dev/null; then
    info "Installing Python 3..."
    brew install python3
fi
ok "Python $(python3 --version 2>&1 | awk '{print $2}')"

# ---------- check / install Pillow ----------
if ! python3 -c "from PIL import Image" 2> /dev/null; then
    info "Installing Pillow..."
    pip3 install Pillow --break-system-packages 2>/dev/null || pip3 install Pillow
fi
ok "Pillow"

echo ""

# ---------- migrate old pokefetch install ----------
# Gated on the LEGACY files existing, not on $INSTALL_DIR being absent: the sereno
# app itself can create ~/.config/sereno before this script ever runs (saving a
# sprite pick calls createDirectory as a side effect), which made the old
# directory-existence guard skip migration entirely on a real machine. Every step
# below is independently idempotent, so re-running this block is always safe.
if [[ -f "$LEGACY_DIR/display_gif.sh" || -f "$LEGACY_DIR/pokefetch_config.json" || -d "$LEGACY_DIR/pokemons" ]]; then
    info "Old pokefetch install detected — migrating"
    mkdir -p "$SPRITES_DIR"
    if [[ -d "$LEGACY_DIR/pokemons" ]]; then
        # Merge, don't clobber: $SPRITES_DIR may already hold the CC0 default pack
        # (or a prior partial migration) — only move sprites not already present.
        while IFS= read -r -d '' f; do
            dest="$SPRITES_DIR/$(basename "$f")"
            [[ -f "$dest" ]] || mv "$f" "$dest"
        done < <(find "$LEGACY_DIR/pokemons" -maxdepth 1 -type f \( -iname '*.gif' -o -iname '*.png' \) -print0 2>/dev/null)
        rmdir "$LEGACY_DIR/pokemons" 2>/dev/null || rm -rf "$LEGACY_DIR/pokemons"
    fi
    if [[ -f "$LEGACY_DIR/pokefetch_config.json" ]]; then
        # Only adopt the legacy selection if sereno doesn't already have a NEWER
        # config — e.g. a pick made in the app before this script ran.
        if [[ ! -f "$INSTALL_DIR/config.json" || "$LEGACY_DIR/pokefetch_config.json" -nt "$INSTALL_DIR/config.json" ]]; then
            mkdir -p "$INSTALL_DIR"
            mv "$LEGACY_DIR/pokefetch_config.json" "$INSTALL_DIR/config.json"
        else
            rm -f "$LEGACY_DIR/pokefetch_config.json"
        fi
    fi
    if [[ -f "$LEGACY_DIR/config.jsonc" && ! -f "$INSTALL_DIR/fastfetch.jsonc" ]]; then
        mkdir -p "$INSTALL_DIR"
        mv "$LEGACY_DIR/config.jsonc" "$INSTALL_DIR/fastfetch.jsonc"
    fi
    rm -f "$LEGACY_DIR/display_gif.sh" "$LEGACY_DIR/get_pokemon.sh" "$LEGACY_DIR/get_color.py"
    # Old zshrc block points at the legacy dir; drop it so the new one replaces it.
    if [[ -f "$HOME/.zshrc" ]] && grep -q "^# pokefetch$" "$HOME/.zshrc"; then
        sed -i '' '/^# pokefetch$/,+2d' "$HOME/.zshrc"
    fi
    ok "Migrated sprites and settings from pokefetch"
fi

# ---------- copy files ----------
info "Installing sereno to ${BOLD}$INSTALL_DIR${NC}"

mkdir -p "$INSTALL_DIR"
mkdir -p "$SPRITES_DIR"

# Don't overwrite a migrated/customized fastfetch.jsonc.
if [[ ! -f "$INSTALL_DIR/fastfetch.jsonc" ]]; then
    cp "$SCRIPT_DIR/fastfetch.jsonc" "$INSTALL_DIR/fastfetch.jsonc"
fi
cp "$SCRIPT_DIR/greet.sh"       "$INSTALL_DIR/greet.sh"
cp "$SCRIPT_DIR/pick_random.sh" "$INSTALL_DIR/pick_random.sh"
cp "$SCRIPT_DIR/get_color.py"   "$INSTALL_DIR/get_color.py"

chmod +x "$INSTALL_DIR/greet.sh"
chmod +x "$INSTALL_DIR/pick_random.sh"

ok "Scripts installed"

# ---------- sprites ----------
# The repo no longer bundles a default sprite pack: themed packs live in
# sprite-packs/ and are downloaded from the app (botón "+"), or you can drop
# your own .gif/.png into $SPRITES_DIR (or drag them onto the app).
EXISTING=$(ls "$SPRITES_DIR/"*.(gif|png)(.N) 2>/dev/null | wc -l | tr -d ' ')
if [[ "$EXISTING" -gt 0 ]]; then
    ok "$EXISTING sprites already in $SPRITES_DIR"
else
    warn "No sprites yet — download themed packs from the sereno app (+ button)"
    warn "or drop .gif/.png files into $SPRITES_DIR"
fi

# ---------- shell integration ----------
ZSHRC="$HOME/.zshrc"
MARKER="# sereno"

if ! grep -q "$MARKER" "$ZSHRC" 2>/dev/null; then
    info "Adding sereno to ${BOLD}~/.zshrc${NC}"
    cat >> "$ZSHRC" << 'EOF'

# sereno
alias c='clear && $HOME/.config/sereno/greet.sh'
$HOME/.config/sereno/greet.sh
EOF
    ok "Shell integration added"
else
    ok "Shell integration already present"
fi

# ---------- done ----------
echo ""
echo "${GREEN}${BOLD}    ✓ sereno installed successfully!${NC}"
echo ""
echo "    Open a new terminal to see it in action,"
echo "    or run: ${BOLD}source ~/.zshrc${NC}"
echo ""
