#!/bin/bash
# Menu rofi para ajustar brillo sin depender de las teclas Fn
source $HOME/.local/bin/rofi-row.sh
THEME="$HOME/.config/rofi/wifi.rasi"

CURRENT=$(brightnessctl -m | awk -F, '{gsub("%","",$4); print $4}')

IDX=$( { rofi_row "󰃠" "Subir" "+10 %"
         rofi_row "󰃞" "Bajar" "−10 %"
         rofi_row "󰃝" "Mínimo"
         rofi_row "󰃠" "Máximo"; } \
    | rofi -dmenu -format i -no-custom -markup-rows -p "Brillo  ${CURRENT} %" -theme "$THEME" -theme-str 'entry { placeholder: ""; }')

case "$IDX" in
    0) brightnessctl set 10%+ ;;
    1) brightnessctl set 10%- ;;
    2) brightnessctl set 1% ;;
    3) brightnessctl set 100% ;;
esac
