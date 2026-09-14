#!/bin/sh
# Script para apagar las luces del teclado ASUS antes de suspender
# y restaurarlas al despertar, evitando el parpadeo en suspensión.

BRIGHTNESS_FILE="/tmp/kbd_brightness"
LEDS_PATH="/sys/class/leds/asus::kbd_backlight/brightness"

case "$1" in
    pre)
        if [ -f "$LEDS_PATH" ]; then
            # Guardar el brillo actual
            cat "$LEDS_PATH" > "$BRIGHTNESS_FILE"
            # Apagar las luces del teclado
            echo 0 > "$LEDS_PATH"
        fi
        ;;
    post)
        if [ -f "$LEDS_PATH" ] && [ -f "$BRIGHTNESS_FILE" ]; then
            # Esperar un segundo a que el hardware del teclado responda tras despertar
            sleep 1
            # Restaurar el brillo que tenía antes de suspender
            cat "$BRIGHTNESS_FILE" > "$LEDS_PATH"
            rm -f "$BRIGHTNESS_FILE"
        fi
        ;;
esac
