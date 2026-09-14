#!/bin/bash
if ! command -v sensors &>/dev/null; then
    notify-send "Temperaturas" "Instala 'lm_sensors' para ver detalles." --icon=temperature-sens
    exit 0
fi

# Obtener temperaturas detalladas de CPU
# Filtramos por las líneas comunes que tienen datos de temperatura relevantes
INFO=$(sensors | grep -E '^(Core|Package|Tctl|temp1|Tdie)' | sed 's/  */ /g')

if [ -z "$INFO" ]; then
    # Fallback si el filtro no devuelve nada
    INFO=$(sensors | head -n 12)
fi

notify-send "Temperaturas de CPU" "$INFO" --icon=temperature-sens
