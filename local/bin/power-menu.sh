#!/bin/bash
# Menú de apagado: cuatro opciones en fila (icono y nombre debajo).
# Filas de dos líneas separadas por "|" (-sep) y elegidas por posición.
row() { printf "<span font_family='JetBrainsMono Nerd Font' size='24pt'>%s</span>\n%s|" "$1" "$2"; }

IDX=$( { row $'\U000f033e' "Bloquear"; row $'\U000f0904' "Suspender"
         row $'\U000f0709' "Reiniciar"; row $'\U000f0425' "Apagar"; } | sed '$ s/|$//' | \
    rofi -dmenu -sep "|" -eh 4 -format i \
         -theme ~/.config/rofi/power-menu.rasi \
         -no-custom \
         -markup-rows \
         -hover-select \
         -me-select-entry '' \
         -me-accept-entry 'MousePrimary' \
         -cache-file /dev/null)

case "$IDX" in
    0) $HOME/.local/bin/hyprlock-launch.sh ;;
    1) systemctl suspend -i ;;
    2) systemctl reboot ;;
    3) systemctl poweroff ;;
esac
