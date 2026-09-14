#!/bin/bash
if ! command -v sensors &>/dev/null; then
    echo '{"text": "CPU --°C", "tooltip": "Instala lm_sensors"}'
    exit 0
fi

# Leer temperatura general
TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
if [ -n "$TEMP" ]; then
    TEMP_C=$((TEMP / 1000))
else
    TEMP_C=$(sensors | grep -E 'Package|Tctl|temp1' | head -n 1 | grep -oP '\+\K[0-9.]+')
    TEMP_C=${TEMP_C%.*}
fi

# Obtener desglose de núcleos
CORES=$(sensors 2>/dev/null | grep -E '^(Core|Package|Tctl|temp1|Tdie)' | sed 's/  */ /g')
[ -z "$CORES" ] && CORES="No se detectaron sensores detallados"

# Escapar para marcado Pango
CORES_SAFE="${CORES//&/&amp;}"
CORES_SAFE="${CORES_SAFE//</&lt;}"
CORES_SAFE="${CORES_SAFE//>/&gt;}"

# Convertir saltos de línea físicos en \n para evitar romper el formato JSON
CORES_JSON=$(echo "$CORES_SAFE" | sed ':a;N;$!ba;s/\n/\\n/g')

# Asignar clase crítica si excede los 80 grados
class=""
if [ $TEMP_C -ge 80 ]; then
    class="critical"
fi

# Output JSON sin emojis (usa Nerd Font 󰔏)
echo "{\"text\": \"󰔏 ${TEMP_C}°C\", \"tooltip\": \"Temperaturas:\\n$CORES_JSON\", \"class\": \"$class\"}"
