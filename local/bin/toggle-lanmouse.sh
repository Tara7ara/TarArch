#!/bin/bash

if pgrep -x lan-mouse > /dev/null; then
    systemctl --user stop lan-mouse.service
    notify-send "KVM" "lan-mouse desactivado"
else
    if ! ip addr show eno2 2>/dev/null | grep -q '192.168.1.30'; then
        notify-send "KVM" "lan-mouse no disponible — eno2 sin IP estática" -u critical
        exit 1
    fi
    systemctl --user start lan-mouse.service
    notify-send "KVM" "lan-mouse activo — W11 en 192.168.1.20"
fi
