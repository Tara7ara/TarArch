#!/bin/bash
# Bloquea la pantalla si el iPhone (emparejado por Bluetooth) se aleja del alcance.
MAC="AA:BB:CC:DD:EE:02"
INTERVAL=15
THRESHOLD=3
LOCK_CMD="/home/tara/.local/bin/hyprlock-launch.sh"
STATE_FILE="/tmp/bt-proximity-status"

fails=0
away=0

while true; do
    if l2ping -c 1 -t 2 "$MAC" >/dev/null 2>&1; then
        fails=0
        away=0
        echo "connected" > "$STATE_FILE"
    else
        fails=$((fails + 1))
        echo "disconnected" > "$STATE_FILE"
        if [[ $fails -ge $THRESHOLD && $away -eq 0 ]]; then
            "$LOCK_CMD"
            away=1
        fi
    fi
    sleep "$INTERVAL"
done
