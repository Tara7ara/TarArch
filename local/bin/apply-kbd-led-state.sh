#!/bin/bash
# Aplica el color blanco puro y el ultimo brillo guardado del teclado ROG.
STATE_DIR="/var/lib/asus-kbd-led"
LEDS="/sys/class/leds/asus::kbd_backlight/brightness"

/home/tara/.local/bin/ensure-asusd-masked.sh

/usr/local/bin/rogauracore initialize_keyboard
/usr/local/bin/rogauracore white

level=$(cat "$STATE_DIR/brightness" 2>/dev/null || echo 2)
echo "$level" > "$LEDS" 2>/dev/null || true
