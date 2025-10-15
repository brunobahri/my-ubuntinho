#!/bin/bash
# Aplica perfil FLAT no touchpad
# Velocidade constante, sem aceleração adaptativa

PROFILE="flat"
SPEED="0.4"

echo "Aplicando perfil FLAT..."
gsettings set org.gnome.desktop.peripherals.touchpad accel-profile "$PROFILE"
gsettings set org.gnome.desktop.peripherals.touchpad speed "$SPEED"

echo ""
echo "✓ Perfil FLAT ativado!"
echo "  - Velocidade CONSTANTE em todos os movimentos"
echo "  - Comportamento PREVISÍVEL"
echo ""
echo "Configurações atuais:"
echo "  Perfil: $(gsettings get org.gnome.desktop.peripherals.touchpad accel-profile)"
echo "  Velocidade: $(gsettings get org.gnome.desktop.peripherals.touchpad speed)"
