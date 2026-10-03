#!/bin/bash
# Abre la NAS en Thunar usando el montaje de fstab (credenciales ya guardadas en /etc/nas-credentials)
# Antes de tocar el automount comprueba en 1s si la NAS responde; si no (fuera de casa sin VPN)
# abre la carpeta personal al momento en vez de quedarse colgado esperando al montaje

NAS_IP="192.168.1.40"
MNT="$HOME/.mounts/TaraNAS"

if timeout 1 bash -c "</dev/tcp/$NAS_IP/445" 2>/dev/null; then
    exec thunar "$MNT"
else
    notify-send -a "TaraNAS" -i network-offline "TaraNAS no disponible" "Sin VPN no llego a la NAS, abro la carpeta local."
    exec thunar "$HOME"
fi
