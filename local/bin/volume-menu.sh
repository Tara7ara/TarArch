#!/bin/bash
# Menu rofi para ajustar volumen sin depender del scroll en Waybar
source $HOME/.local/bin/rofi-row.sh
THEME="$HOME/.config/rofi/wifi.rasi"

ROW=0

while true; do
    VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%.0f", $2*100}')
    if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED; then
        MUTE_ROW=$(rofi_row "󰕾" "Reactivar sonido")
    else
        MUTE_ROW=$(rofi_row "󰝟" "Silenciar")
    fi

    IDX=$( { rofi_row "󰝝" "Subir" "+5 %"
             rofi_row "󰝞" "Bajar" "−5 %"
             echo "$MUTE_ROW"
             rofi_row "󰓃" "Elegir salida de audio"; } \
        | rofi -dmenu -format i -no-custom -markup-rows -p "Volumen  ${VOL} %" -theme "$THEME" -theme-str 'entry { placeholder: ""; }' -selected-row "$ROW")

    # Esc o cierre sin elegir nada -> salir del bucle
    [[ -z "$IDX" ]] && break

    case "$IDX" in
        0) ROW=0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
        1) ROW=1; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
        2) ROW=2; wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
        3) ROW=0; $HOME/.local/bin/audio-output-menu.sh ;;
    esac
done
