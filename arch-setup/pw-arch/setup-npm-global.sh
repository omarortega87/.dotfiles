#!/usr/bin/env bash
# setup-npm-global.sh -- Configure npm for sudo-free global installs (Arch)
#
# Sets npm prefix to ~/.npm-global and adds it to PATH for bash/zsh/fish.
# Distro-independent; kept alongside the Arch Playwright setup for parity
# with fedora-setup/pw-fedora.

set -euo pipefail

NPM_GLOBAL_DIR="$HOME/.npm-global"

echo "Configuring npm global prefix to $NPM_GLOBAL_DIR..."

mkdir -p "$NPM_GLOBAL_DIR"
npm config set prefix "$NPM_GLOBAL_DIR"

add_to_path() {
    local file="$1" pattern="$2" line="$3"
    [ -f "$file" ] || return 0
    grep -q "$pattern" "$file" 2>/dev/null && return 0
    echo "$line" >> "$file"
    echo "  Updated $file"
}

add_to_path "$HOME/.bashrc" 'npm-global' 'export PATH="$HOME/.npm-global/bin:$PATH"'
add_to_path "$HOME/.zshrc"  'npm-global' 'export PATH="$HOME/.npm-global/bin:$PATH"'
add_to_path "$HOME/.config/fish/config.fish" 'npm-global' 'set -gx PATH $HOME/.npm-global/bin $PATH'

echo ""
echo "Done. Global npm installs will no longer require sudo."
echo "Run: source ~/.zshrc  (or restart your shell)"
