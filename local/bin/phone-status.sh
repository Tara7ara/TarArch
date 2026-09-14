#!/bin/bash
STATE_FILE="/tmp/bt-proximity-status"

# Si el adaptador Bluetooth está apagado, ocultar el módulo entero
if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    echo '{"text":"","class":"hidden","tooltip":"Bluetooth apagado"}'
    exit 0
fi

if ! systemctl --user is-active --quiet bt-proximity-lock.service; then
    echo '{"text":"󰄜","class":"phone-off","tooltip":"Bloqueo por proximidad: inactivo"}'
    exit 0
fi

if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" == "connected" ]]; then
    echo '{"text":"󰄜","class":"phone-connected","tooltip":"iPhone conectado — bloqueo por proximidad activo"}'
else
    echo '{"text":"󰄜","class":"phone-disconnected","tooltip":"Buscando iPhone…"}'
fi
