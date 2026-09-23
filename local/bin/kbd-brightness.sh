#!/bin/bash
# Sube/baja el brillo del teclado ROG (Super+Shift+flechas arriba/abajo).
# Guarda el valor en /var/lib para que apply-kbd-led-state.sh lo restaure al arrancar.
LEDS="/sys/class/leds/asus::kbd_backlight/brightness"
MAX=$(cat "/sys/class/leds/asus::kbd_backlight/max_brightness")
STATE="/var/lib/asus-kbd-led/brightness"
current=$(cat "$LEDS")

/home/tara/.local/bin/ensure-asusd-masked.sh

case "$1" in
    up)   new=$(( current + 1 )); [ "$new" -gt "$MAX" ] && new=$MAX ;;
    down) new=$(( current - 1 )); [ "$new" -lt 0 ] && new=0 ;;
    *) exit 1 ;;
esac

echo "$new" > "$LEDS"
echo "$new" > "$STATE"
