#!/bin/bash
# Script para configurar touchpad e desativar tap-and-drag
# Autor: Bruno Bahri
# Data: 2025-10-15
#
# Uso: ./fix-touchpad.sh

echo "================================================"
echo "  Configurando Touchpad - Ubuntu"
echo "================================================"
echo ""

# Desativa tap-and-drag (dois toques rápidos = drag mode)
echo "[1/4] Desativando tap-and-drag..."
gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag false

# Garante que tap-and-drag-lock também está desativado
echo "[2/4] Desativando tap-and-drag-lock..."
gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag-lock false

# Configura perfil de aceleração adaptativo (movimentos lentos = preciso, rápidos = rápido)
echo "[3/4] Configurando perfil de aceleração ADAPTIVE..."
gsettings set org.gnome.desktop.peripherals.touchpad accel-profile 'adaptive'

# Define velocidade otimizada
echo "[4/4] Ajustando velocidade..."
gsettings set org.gnome.desktop.peripherals.touchpad speed 0.5

# Exibe configurações atuais
echo ""
echo "Configurações atuais do touchpad:"
echo "-----------------------------------"
echo "tap-and-drag:          $(gsettings get org.gnome.desktop.peripherals.touchpad tap-and-drag)"
echo "tap-and-drag-lock:     $(gsettings get org.gnome.desktop.peripherals.touchpad tap-and-drag-lock)"
echo "accel-profile:         $(gsettings get org.gnome.desktop.peripherals.touchpad accel-profile)"
echo "speed:                 $(gsettings get org.gnome.desktop.peripherals.touchpad speed)"
echo "disable-while-typing:  $(gsettings get org.gnome.desktop.peripherals.touchpad disable-while-typing)"
echo "tap-to-click:          $(gsettings get org.gnome.desktop.peripherals.touchpad tap-to-click)"
echo "natural-scroll:        $(gsettings get org.gnome.desktop.peripherals.touchpad natural-scroll)"
echo ""
echo "================================================"
echo "  ✓ Touchpad configurado com sucesso!"
echo "================================================"
echo ""
echo "Dica: Para reverter, execute:"
echo "  gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag true"
echo ""
