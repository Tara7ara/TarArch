#!/bin/bash
# Menu rofi para elegir perfil de energia (power-profiles-daemon)
source $HOME/.local/bin/rofi-row.sh
THEME="$HOME/.config/rofi/wifi.rasi"

CURRENT=$(powerprofilesctl get 2>/dev/null)
act() { [ "$1" = "$CURRENT" ] && echo activo; }

IDX=$( { rofi_row "󰓅" "Rendimiento" "" "$(act performance)"
         rofi_row "󰾅" "Equilibrado" "" "$(act balanced)"
         rofi_row "󰾆" "Ahorro" "" "$(act power-saver)"; } \
    | rofi -dmenu -format i -no-custom -markup-rows -p "Perfil de energía" -theme "$THEME" -theme-str 'entry { placeholder: ""; }')

case "$IDX" in
    0) powerprofilesctl set performance ;;
    1) powerprofilesctl set balanced ;;
    2) powerprofilesctl set power-saver ;;
esac
