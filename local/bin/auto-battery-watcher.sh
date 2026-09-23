#!/bin/bash
# Cambia a 60 Hz con batería y a 144 Hz enchufado

AC_FILE="/sys/class/power_supply/AC0/online"
[ ! -f "$AC_FILE" ] && exit 1

LAST_STATE=""

while true; do
    STATE=$(cat "$AC_FILE" 2>/dev/null)
    
    if [ "$STATE" != "$LAST_STATE" ]; then
        if [ "$STATE" = "0" ]; then
            # Modo Batería (Desconectado de la corriente en la uni)
            /home/tara/.local/bin/toggle-power-profile.sh battery
        elif [ "$STATE" = "1" ]; then
            # Modo Enchufado (Conectado a la corriente)
            /home/tara/.local/bin/toggle-power-profile.sh performance
        fi
        LAST_STATE="$STATE"
    fi
    
    sleep 3
done
