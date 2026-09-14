#!/bin/bash
# Menu rofi para ajustar brillo sin depender de las teclas Fn
THEME="$HOME/.config/rofi/wifi.rasi"

CURRENT=$(brightnessctl -m | awk -F, '{gsub("%","",$4); print $4}')

CHOICE=$(printf "☀️  Subir brillo (+10%%)\n🌙  Bajar brillo (-10%%)\n🔅  Brillo mínimo\n🔆  Brillo máximo" \
    | rofi -dmenu -p "Brillo · ${CURRENT}%" -theme "$THEME")

case "$CHOICE" in
    *"Subir brillo"*) brightnessctl set 10%+ ;;
    *"Bajar brillo"*) brightnessctl set 10%- ;;
    *"mínimo"*) brightnessctl set 1% ;;
    *"máximo"*) brightnessctl set 100% ;;
esac
