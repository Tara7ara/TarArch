#!/bin/bash
# Registra el drenaje de bateria cada 5 min a un CSV, para comparar autonomia antes/despues del cambio de bateria.
# Uso: ./battery-drain-log.sh [archivo_salida.csv]
# Parar con Ctrl+C o: pkill -f battery-drain-log.sh

OUT="${1:-$HOME/bateria-test-$(date +%Y%m%d-%H%M).csv}"
BAT="/sys/class/power_supply/BAT0"

echo "timestamp,percent,energy_wh,rate_w,state" > "$OUT"
echo "Registrando en $OUT (Ctrl+C para parar)"

while true; do
    PCT=$(cat "$BAT/capacity")
    ENERGY=$(awk "BEGIN{printf \"%.2f\", $(cat "$BAT/energy_now")/1000000}")
    RATE=$(awk "BEGIN{printf \"%.2f\", $(cat "$BAT/power_now")/1000000}")
    STATE=$(cat "$BAT/status")
    echo "$(date '+%Y-%m-%d %H:%M:%S'),$PCT,$ENERGY,$RATE,$STATE" >> "$OUT"
    if [ "$STATE" = "Discharging" ] && [ "$PCT" -le 3 ]; then
        echo "Bateria casi agotada, parando log."
        break
    fi
    sleep 300
done
