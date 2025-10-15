#!/bin/bash
# my-ubuntinho - Ubuntu Configuration Scripts
# Install script: Creates symlinks and sets up the environment
# Author: Bruno Bahri

set -e  # Exit on error

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$HOME/scripts"
AUTOSTART_DIR="$HOME/.config/autostart"

echo "================================================"
echo "  my-ubuntinho - Installation"
echo "================================================"
echo ""
echo "Dotfiles directory: $DOTFILES_DIR"
echo ""

# Create directories if they don't exist
echo "[1/4] Creating directories..."
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$AUTOSTART_DIR"
echo "  ✓ Directories created"

# Create symlinks for touchpad scripts
echo ""
echo "[2/4] Creating symlinks for touchpad scripts..."

# Remove old files if they exist
rm -f "$SCRIPTS_DIR/touchpad-adaptive.sh"
rm -f "$SCRIPTS_DIR/touchpad-flat.sh"
rm -f "$SCRIPTS_DIR/touchpad-reset.sh"
rm -f "$SCRIPTS_DIR/touchpad-accel.sh"
rm -f "$SCRIPTS_DIR/fix-touchpad.sh"

# Create new symlinks
ln -s "$DOTFILES_DIR/scripts/touchpad/adaptive.sh" "$SCRIPTS_DIR/touchpad-adaptive.sh"
ln -s "$DOTFILES_DIR/scripts/touchpad/flat.sh" "$SCRIPTS_DIR/touchpad-flat.sh"
ln -s "$DOTFILES_DIR/scripts/touchpad/reset.sh" "$SCRIPTS_DIR/touchpad-reset.sh"
ln -s "$DOTFILES_DIR/scripts/touchpad/config.sh" "$SCRIPTS_DIR/touchpad-accel.sh"
ln -s "$DOTFILES_DIR/scripts/touchpad/fix-all.sh" "$SCRIPTS_DIR/fix-touchpad.sh"

echo "  ✓ Symlinks created in $SCRIPTS_DIR"

# Make scripts executable
echo ""
echo "[3/4] Making scripts executable..."
chmod +x "$DOTFILES_DIR"/scripts/touchpad/*.sh
echo "  ✓ Scripts are now executable"

# Create autostart symlink
echo ""
echo "[4/4] Setting up autostart..."
rm -f "$AUTOSTART_DIR/touchpad-config.desktop"
ln -s "$DOTFILES_DIR/autostart/touchpad-config.desktop" "$AUTOSTART_DIR/touchpad-config.desktop"
echo "  ✓ Autostart configured"

echo ""
echo "================================================"
echo "  ✓ Installation completed successfully!"
echo "================================================"
echo ""
echo "Available commands:"
echo "  tpad-adaptive    - Enable adaptive acceleration profile"
echo "  tpad-flat        - Enable flat acceleration profile"
echo "  tpad-reset       - Reset to default settings"
echo "  tpad-config      - Interactive configuration menu"
echo "  tpad-status      - Show current touchpad settings"
echo ""
echo "Note: If aliases don't work, add them to your ~/.zshrc:"
echo "  alias tpad-adaptive='~/scripts/touchpad-adaptive.sh'"
echo "  alias tpad-flat='~/scripts/touchpad-flat.sh'"
echo "  alias tpad-reset='~/scripts/touchpad-reset.sh'"
echo "  alias tpad-config='~/scripts/touchpad-accel.sh'"
echo "  alias tpad-status='gsettings list-recursively org.gnome.desktop.peripherals.touchpad | grep -E \"accel|speed|tap-and-drag\"'"
echo ""
echo "Then run: source ~/.zshrc"
echo ""
