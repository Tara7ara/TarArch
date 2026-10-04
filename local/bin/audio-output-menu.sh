#!/bin/bash
# Menu rofi para elegir la salida de audio (altavoces internos, HDMI, etc.) sin pavucontrol.
source $HOME/.local/bin/rofi-row.sh
THEME="$HOME/.config/rofi/wifi.rasi"

CURRENT=$(pactl get-default-sink)

NAMES=()
ROWS=()
while IFS='|' read -r name desc; do
    [[ -z "$name" ]] && continue
    NAMES+=("$name")
    if [[ "$name" == "$CURRENT" ]]; then
        ROWS+=("$(rofi_row "󰓃" "$desc" "en uso" activo)")
    else
        ROWS+=("$(rofi_row "󰓃" "$desc")")
    fi
done < <(pactl list sinks | awk -F': ' '/^Sink #/{name="";desc=""} /^\tName:/{name=$2} /^\tDescription:/{desc=$2; print name"|"desc}')

IDX=$(printf "%s\n" "${ROWS[@]}" | rofi -dmenu -format i -no-custom -markup-rows -p "Salida de audio" -theme "$THEME" -theme-str 'entry { placeholder: ""; }')
[[ -z "$IDX" ]] && exit 0

SELECTED="${NAMES[$IDX]}"
[[ -z "$SELECTED" || "$SELECTED" == "$CURRENT" ]] && exit 0

pactl set-default-sink "$SELECTED"

# Mueve los streams que ya estaban sonando al nuevo destino, si no se queda mudo el que estaba activo
while read -r sink_input; do
    [[ -n "$sink_input" ]] && pactl move-sink-input "$sink_input" "$SELECTED"
done < <(pactl list short sink-inputs | awk '{print $1}')

DESC=$(pactl list sinks | awk -F': ' -v s="$SELECTED" '/^Sink #/{name=""} /^\tName:/{name=$2} /^\tDescription:/{if(name==s) print $2}')
notify-send "Salida de audio" "$DESC"
