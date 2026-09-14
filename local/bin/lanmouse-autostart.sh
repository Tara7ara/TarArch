#!/bin/bash
# Script de arranque inteligente para lan-mouse

# 1. Comprobar si tenemos la IP de casa en la interfaz ethernet
if ip addr show eno2 2>/dev/null | grep -q '192.168.1.30'; then
    # 2. Comprobar si el PC W11 de destino está encendido (ping de 1 segundo de timeout)
    if ping -c 1 -W 1 192.168.1.20 >/dev/null 2>&1; then
        # Ambas condiciones se cumplen: arrancar el servicio
        systemctl --user start lan-mouse.service
        notify-send "KVM (Autostart)" "lan-mouse activo — Conectado a W11"
        exit 0
    fi
fi

# Si no estamos en casa o el PC W11 está apagado, forzar apagado para no interferir con el ratón
systemctl --user stop lan-mouse.service
