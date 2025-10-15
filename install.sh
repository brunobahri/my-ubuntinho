#!/bin/bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTOSTART_DIR="$HOME/.config/autostart"

mkdir -p "$AUTOSTART_DIR"

chmod +x "$DOTFILES_DIR"/scripts/touchpad/*.sh

rm -f "$AUTOSTART_DIR/touchpad-config.desktop"
ln -s "$DOTFILES_DIR/autostart/touchpad-config.desktop" "$AUTOSTART_DIR/touchpad-config.desktop"

echo "✓ Touchpad tap-and-drag fix installed"
echo "  Will run automatically on login"
