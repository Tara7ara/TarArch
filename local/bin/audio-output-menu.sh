#!/bin/bash
# Menu rofi para elegir la salida de audio (altavoces internos, HDMI, etc.) sin pavucontrol.
THEME="$HOME/.config/rofi/wifi.rasi"
ICON_SPEAKER=$(python3 -c "print(chr(0xf0299))")
ICON_CHECK=$(python3 -c "print(chr(0xf05f0))")

rofi_menu() {
    rofi -dmenu -p "$1" -theme "$THEME" -markup-rows
}

CURRENT=$(pactl get-default-sink)

declare -A LINE_NAME
menu_lines=""

while IFS='|' read -r name desc; do
    [[ -z "$name" ]] && continue
    if [[ "$name" == "$CURRENT" ]]; then
        display="${ICON_CHECK}  ${desc}"
    else
        display="${ICON_SPEAKER}  ${desc}"
    fi
    menu_lines="${menu_lines}${display}\n"
    LINE_NAME["$display"]="$name"
done < <(pactl list sinks | awk -F': ' '/^Sink #/{name="";desc=""} /^\tName:/{name=$2} /^\tDescription:/{desc=$2; print name"|"desc}')

CHOICE=$(echo -e "$menu_lines" | rofi_menu "$ICON_SPEAKER Salida de audio")
[[ -z "$CHOICE" ]] && exit 0

SELECTED="${LINE_NAME[$CHOICE]}"
[[ -z "$SELECTED" || "$SELECTED" == "$CURRENT" ]] && exit 0

pactl set-default-sink "$SELECTED"

# Mueve los streams que ya estaban sonando al nuevo destino, si no se queda mudo el que estaba activo
while read -r sink_input; do
    [[ -n "$sink_input" ]] && pactl move-sink-input "$sink_input" "$SELECTED"
done < <(pactl list short sink-inputs | awk '{print $1}')

DESC=$(pactl list sinks | awk -F': ' -v s="$SELECTED" '/^Sink #/{name=""} /^\tName:/{name=$2} /^\tDescription:/{if(name==s) print $2}')
notify-send "Salida de audio" "$DESC"
