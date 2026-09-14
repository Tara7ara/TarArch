#!/bin/bash
BAT_PATH=$(upower -e | grep 'BAT' | head -n 1)
if [ -z "$BAT_PATH" ]; then
    notify-send "Batería" "No se detectó ninguna batería en el sistema." --icon=battery
    exit 0
fi

INFO=$(upower -i "$BAT_PATH")

# Extraer y traducir campos básicos
STATE=$(echo "$INFO" | grep 'state:' | awk '{print $2}')
PERCENT=$(echo "$INFO" | grep 'percentage:' | awk '{print $2}')
HEALTH=$(echo "$INFO" | grep 'capacity:' | awk '{print $2}')
TIME=$(echo "$INFO" | grep -E 'time to empty|time to full' | cut -d':' -f2- | xargs)
TECH=$(echo "$INFO" | grep 'technology:' | awk '{print $2}')

# Traducir estados comunes
case "$STATE" in
    "fully-charged") STATE_ES="Totalmente cargada" ;;
    "charging")      STATE_ES="Cargando" ;;
    "discharging")   STATE_ES="Descargando" ;;
    "empty")         STATE_ES="Vacía" ;;
    *)               STATE_ES="$STATE" ;;
esac

[ -z "$TIME" ] && TIME="N/D (Cargada o calculando)"
[ -z "$HEALTH" ] && HEALTH="Desconocida"

MSG="<b>Estado:</b> $STATE_ES\n<b>Nivel:</b> $PERCENT\n<b>Restante:</b> $TIME\n<b>Salud:</b> $HEALTH\n<b>Tecnología:</b> $TECH"

notify-send "Información de Batería" "$MSG" --icon=battery
