#!/bin/bash
# Menu rofi para ajustar volumen sin depender del scroll en Waybar
THEME="$HOME/.config/rofi/wifi.rasi"

ROW=0

while true; do
    VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%.0f", $2*100}')
    MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo yes || echo no)
    MUTE_LABEL="🔇  Silenciar"
    [ "$MUTED" = "yes" ] && MUTE_LABEL="🔊  Reactivar sonido"

    CHOICE=$(printf "🔊  Subir volumen (+5%%)\n🔉  Bajar volumen (-5%%)\n%s\n🎚  Elegir salida de audio" "$MUTE_LABEL" \
        | rofi -dmenu -p "Volumen · ${VOL}%" -theme "$THEME" -selected-row "$ROW")

    # Esc o cierre sin elegir nada -> salir del bucle
    [[ -z "$CHOICE" ]] && break

    case "$CHOICE" in
        *"Subir volumen"*) ROW=0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
        *"Bajar volumen"*) ROW=1; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
        *"Silenciar"*|*"Reactivar sonido"*) ROW=2; wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
        *"salida"*) ROW=0; /home/tara/.local/bin/audio-output-menu.sh ;;
    esac
done
