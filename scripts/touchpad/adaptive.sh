#!/bin/bash
# Aplica perfil ADAPTIVE no touchpad
# Movimentos lentos = precisão | Movimentos rápidos = velocidade

PROFILE="adaptive"
SPEED="0.5"

echo "Aplicando perfil ADAPTIVE..."
gsettings set org.gnome.desktop.peripherals.touchpad accel-profile "$PROFILE"
gsettings set org.gnome.desktop.peripherals.touchpad speed "$SPEED"

echo ""
echo "✓ Perfil ADAPTIVE ativado!"
echo "  - Movimentos lentos/pequenos: PRECISO"
echo "  - Movimentos rápidos/grandes: RÁPIDO"
echo ""
echo "Configurações atuais:"
echo "  Perfil: $(gsettings get org.gnome.desktop.peripherals.touchpad accel-profile)"
echo "  Velocidade: $(gsettings get org.gnome.desktop.peripherals.touchpad speed)"
