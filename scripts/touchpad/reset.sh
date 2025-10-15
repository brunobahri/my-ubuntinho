#!/bin/bash
# Reseta touchpad para configurações padrão

PROFILE="default"
SPEED="0.0"

echo "Resetando touchpad para configurações padrão..."
gsettings set org.gnome.desktop.peripherals.touchpad accel-profile "$PROFILE"
gsettings set org.gnome.desktop.peripherals.touchpad speed "$SPEED"

echo ""
echo "✓ Touchpad resetado para PADRÃO!"
echo "  - Perfil: default (padrão do dispositivo)"
echo "  - Velocidade: 0.0 (padrão do sistema)"
echo ""
echo "Configurações atuais:"
echo "  Perfil: $(gsettings get org.gnome.desktop.peripherals.touchpad accel-profile)"
echo "  Velocidade: $(gsettings get org.gnome.desktop.peripherals.touchpad speed)"
