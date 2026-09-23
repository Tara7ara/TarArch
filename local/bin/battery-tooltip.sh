#!/bin/bash
BAT_PATH=$(upower -e | grep 'BAT' | head -n 1)
if [ -z "$BAT_PATH" ]; then
    echo '{"text": "N/D", "tooltip": "No se detectó batería"}'
    exit 0
fi

INFO=$(upower -i "$BAT_PATH")

STATE=$(echo "$INFO" | grep 'state:' | awk '{print $2}')
PERCENT=$(echo "$INFO" | grep 'percentage:' | awk '{print $2}')
HEALTH=$(echo "$INFO" | grep 'capacity:' | awk '{print $2}')
TIME=$(echo "$INFO" | grep -E 'time to empty|time to full' | cut -d':' -f2- | xargs)
TECH=$(echo "$INFO" | grep 'technology:' | awk '{print $2}')

case "$STATE" in
    "fully-charged") STATE_ES="Totalmente cargada"; icon="󰂄" ;;
    "charging")      STATE_ES="Cargando"; icon="󱐌" ;;
    "discharging")   STATE_ES="Descargando"; icon="󰁹" ;;
    "empty")         STATE_ES="Vacía"; icon="󰂎" ;;
    *)               STATE_ES="$STATE"; icon="󰁹" ;;
esac

[ -z "$TIME" ] && TIME="N/D (Cargada o calculando)"
[ -z "$HEALTH" ] && HEALTH="N/D"

# Media de consumo de los últimos 15 min, upower solo da el instantáneo
SAMPLES_FILE="/tmp/battery-rate-samples.log"
WINDOW=900   # 15 min de ventana
MIN_SPAN=120 # mínimo 2 min de historial

if [ "$STATE" = "discharging" ]; then
    ENERGY=$(echo "$INFO" | grep 'energy:' | awk '{print $2}' | tr ',' '.')
    SECS=$(date +%s)
    if [ -n "$ENERGY" ]; then
        echo "$SECS $ENERGY" >> "$SAMPLES_FILE"
        awk -v now="$SECS" -v win="$WINDOW" '$1 >= now - win' "$SAMPLES_FILE" > "${SAMPLES_FILE}.tmp" 2>/dev/null \
            && mv "${SAMPLES_FILE}.tmp" "$SAMPLES_FILE"

        read -r OLDEST_SECS OLDEST_ENERGY < "$SAMPLES_FILE"
        SPAN=$((SECS - OLDEST_SECS))

        if [ "$SPAN" -ge "$MIN_SPAN" ]; then
            REAL_TIME=$(awk -v e0="$OLDEST_ENERGY" -v e1="$ENERGY" -v s="$SPAN" '
                BEGIN {
                    rate = (e0 - e1) / (s / 3600)
                    if (rate <= 0) { exit 1 }
                    h = e1 / rate
                    hh = int(h)
                    mm = int((h - hh) * 60 + 0.5)
                    if (mm == 60) { hh++; mm = 0 }
                    printf "%dh %02dm (~%.0fW reales)", hh, mm, rate
                }')
            [ -n "$REAL_TIME" ] && TIME="$REAL_TIME"
        fi
    fi
else
    # cargando / cargada: limpiar historial para que no ensucie la próxima descarga
    rm -f "$SAMPLES_FILE"
fi

# Determinar icono de batería según porcentaje si está descargando
NUM=${PERCENT%\%}
if [ "$STATE" = "discharging" ]; then
    if [ $NUM -le 15 ]; then icon="󰁺"
    elif [ $NUM -le 30 ]; then icon="󰁼"
    elif [ $NUM -le 50 ]; then icon="󰁾"
    elif [ $NUM -le 80 ]; then icon="󰂀"
    else icon="󰁹"
    fi
fi

# Asignar clase de estado según el porcentaje
class=""
if [ $NUM -le 15 ]; then
    class="critical"
elif [ $NUM -le 30 ]; then
    class="warning"
fi

if sudo -n nft list table inet filter &>/dev/null; then
    FW_ES="Activo"
else
    FW_ES="Inactivo"
fi

# Cuerpo del tooltip
RAW_TOOLTIP="Detalles de Batería:\nEstado: $STATE_ES\nRestante: $TIME\nSalud: $HEALTH\nTecnología: $TECH\n\nFirewall: $FW_ES"

# Escapar para Pango
TOOLTIP_SAFE="${RAW_TOOLTIP//&/&amp;}"
TOOLTIP_SAFE="${TOOLTIP_SAFE//</&lt;}"
TOOLTIP_SAFE="${TOOLTIP_SAFE//>/&gt;}"

# Saltos de línea a \n
TOOLTIP_JSON=$(echo "$TOOLTIP_SAFE" | sed ':a;N;$!ba;s/\n/\\n/g')

echo "{\"text\": \"$PERCENT\", \"tooltip\": \"$TOOLTIP_JSON\", \"class\": \"$class\"}"
