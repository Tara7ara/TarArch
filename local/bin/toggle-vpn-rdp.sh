#!/bin/bash
W11_IP="192.168.1.20"
W11_USER="usuario"
W11_MAC="AA:BB:CC:DD:EE:01"
WG_INTERFACE="Portatil"
W11_PASS_FILE="/home/tara/.ssh/.w11_pass"

FREERDP=$(command -v xfreerdp3 || command -v xfreerdp)

LM_WAS_RUNNING=0
if systemctl --user is-active --quiet lan-mouse.service; then
    LM_WAS_RUNNING=1
    systemctl --user stop lan-mouse.service
fi

# Solo activa VPN si no está ya UP — nunca la desactiva
if ! ip link show "$WG_INTERFACE" 2>/dev/null | grep -q "UP"; then
    echo "Activando VPN ($WG_INTERFACE)..."
    nmcli connection up "$WG_INTERFACE"
    sleep 2
fi

# Wake-on-LAN: solo si el PC no responde a ping (nunca se manda el magic packet si ya está encendido).
echo "Comprobando si PC Windows esta encendido..."
if ! ping -c 1 -W 1 "$W11_IP" &>/dev/null; then
    echo "PC Windows no responde. Enviando Wake-on-LAN via servidor..."
    notify-send "RDP" "PC Windows apagado, enviando Wake-on-LAN..."
    ssh servidor "wakeonlan -i 192.168.1.255 $W11_MAC"

    UP=0
    for i in $(seq 1 30); do
        echo "Esperando a que arranque... intento $i/30"
        sleep 2
        if ping -c 1 -W 1 "$W11_IP" &>/dev/null; then
            UP=1
            break
        fi
    done

    if [ "$UP" -eq 0 ]; then
        echo "PC Windows no respondio tras 60s. Cancelado."
        notify-send "RDP" "PC Windows no responde tras el Wake-on-LAN (60s), cancelado"
        [ "$LM_WAS_RUNNING" -eq 1 ] && systemctl --user start lan-mouse.service
        exit 1
    fi

    echo "PC Windows ya responde a ping. Esperando a que el servicio RDP este listo..."
    sleep 5
else
    echo "PC Windows ya estaba encendido."
fi

echo "Lanzando RDP con Portapapeles Bidireccional y Wallpaper activado..."

# Parámetros optimizados para calidad LAN, Wallpaper Engine (DWM Aero), 32-bit y Portapapeles
RDP_ARGS=(
    /v:"$W11_IP"
    /u:"$W11_USER"
    /d:workgroup
    /f
    /cert:ignore
    +clipboard
    +wallpaper
    +aero
    +fonts
    +window-drag
    /gfx:progressive
    /network:lan
    /bpp:32
    /gdi:hw
    /sound:sys:pulse
)

if [ -r "$W11_PASS_FILE" ]; then
    "$FREERDP" "${RDP_ARGS[@]}" /p:"$(cat "$W11_PASS_FILE")"
else
    "$FREERDP" "${RDP_ARGS[@]}"
fi

if [ "$LM_WAS_RUNNING" -eq 1 ]; then
    systemctl --user start lan-mouse.service
fi
