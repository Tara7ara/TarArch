#!/bin/bash
# Menú de apagado
CHOICE=$(printf '<span color="#bb9af7">\U000f033e</span>\n<span color="#e0af68">\U000f0904</span>\n<span color="#ff9e64">\U000f0709</span>\n<span color="#ff6e6e">\U000f0425</span>' | \
    rofi -dmenu \
         -theme ~/.config/rofi/power-menu.rasi \
         -no-custom \
         -markup-rows \
         -hover-select \
         -me-select-entry '' \
         -me-accept-entry 'MousePrimary' \
         -cache-file /dev/null)

case "$CHOICE" in
    *$'\U000f033e'*) /home/tara/.local/bin/hyprlock-launch.sh ;;
    *$'\U000f0904'*) systemctl suspend ;;
    *$'\U000f0709'*) systemctl reboot ;;
    *$'\U000f0425'*) systemctl poweroff ;;
esac
