#!/bin/bash
# Script interativo para configurar aceleração do touchpad
# Permite testar diferentes perfis e velocidades

echo "========================================================"
echo "  Configurador de Aceleração do Touchpad"
echo "========================================================"
echo ""

# Mostra configurações atuais
echo "Configurações ATUAIS:"
echo "---------------------"
CURRENT_PROFILE=$(gsettings get org.gnome.desktop.peripherals.touchpad accel-profile)
CURRENT_SPEED=$(gsettings get org.gnome.desktop.peripherals.touchpad speed)
echo "  Perfil: $CURRENT_PROFILE"
echo "  Velocidade: $CURRENT_SPEED"
echo ""

# Menu de perfis
echo "========================================================"
echo "Escolha um PERFIL de aceleração:"
echo "========================================================"
echo ""
echo "1) ADAPTIVE (recomendado)"
echo "   - Movimentos lentos/pequenos = PRECISO"
echo "   - Movimentos rápidos/grandes = RÁPIDO"
echo "   - Ideal para trabalho geral"
echo ""
echo "2) FLAT"
echo "   - Velocidade CONSTANTE"
echo "   - Comportamento PREVISÍVEL"
echo "   - Ideal para quem gosta de controle total"
echo ""
echo "3) DEFAULT"
echo "   - Padrão do dispositivo"
echo ""
echo "4) Apenas ajustar VELOCIDADE (manter perfil atual)"
echo ""
echo "0) Sair"
echo ""
read -p "Escolha uma opção [0-4]: " profile_choice

case $profile_choice in
    1)
        PROFILE="adaptive"
        DEFAULT_SPEED="0.5"
        ;;
    2)
        PROFILE="flat"
        DEFAULT_SPEED="0.4"
        ;;
    3)
        PROFILE="default"
        DEFAULT_SPEED="0.0"
        ;;
    4)
        PROFILE=$CURRENT_PROFILE
        DEFAULT_SPEED=$CURRENT_SPEED
        echo ""
        echo "Mantendo perfil atual: $PROFILE"
        ;;
    0)
        echo "Saindo..."
        exit 0
        ;;
    *)
        echo "Opção inválida!"
        exit 1
        ;;
esac

# Menu de velocidade
echo ""
echo "========================================================"
echo "Escolha a VELOCIDADE:"
echo "========================================================"
echo ""
echo "Velocidade atual: $CURRENT_SPEED"
echo "Faixa permitida: -1.0 (muito lento) a 1.0 (muito rápido)"
echo "Valor padrão: 0.0"
echo ""
read -p "Digite a velocidade desejada [$DEFAULT_SPEED]: " speed_input

# Usa valor padrão se nada for digitado
if [ -z "$speed_input" ]; then
    SPEED=$DEFAULT_SPEED
else
    SPEED=$speed_input
fi

# Aplica configurações
echo ""
echo "Aplicando configurações..."
gsettings set org.gnome.desktop.peripherals.touchpad accel-profile "$PROFILE"
gsettings set org.gnome.desktop.peripherals.touchpad speed "$SPEED"

# Confirma
echo ""
echo "========================================================"
echo "  ✓ Configurações aplicadas com sucesso!"
echo "========================================================"
echo ""
echo "Novas configurações:"
echo "  Perfil: $(gsettings get org.gnome.desktop.peripherals.touchpad accel-profile)"
echo "  Velocidade: $(gsettings get org.gnome.desktop.peripherals.touchpad speed)"
echo ""
echo "Teste agora o touchpad!"
echo ""
echo "Para reverter, use os scripts rápidos:"
echo "  ~/scripts/touchpad-adaptive.sh"
echo "  ~/scripts/touchpad-flat.sh"
echo "  ~/scripts/touchpad-reset.sh"
echo ""
