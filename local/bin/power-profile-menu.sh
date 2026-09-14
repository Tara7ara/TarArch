#!/bin/bash
# Menu rofi para elegir perfil de energia (power-profiles-daemon)
THEME="$HOME/.config/rofi/wifi.rasi"

CURRENT=$(powerprofilesctl get 2>/dev/null)

mark() { [ "$1" = "$CURRENT" ] && echo "●" || echo "○"; }

CHOICE=$(printf "%s 󰓁  Rendimiento\n%s 󰔳  Equilibrado\n%s 󰑈  Ahorro" \
    "$(mark performance)" "$(mark balanced)" "$(mark power-saver)" \
    | rofi -dmenu -p "Perfil de energia . ${CURRENT}" -theme "$THEME")

case "$CHOICE" in
    *"Rendimiento"*) powerprofilesctl set performance ;;
    *"Equilibrado"*) powerprofilesctl set balanced ;;
    *"Ahorro"*) powerprofilesctl set power-saver ;;
esac
