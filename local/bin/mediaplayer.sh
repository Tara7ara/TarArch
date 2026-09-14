#!/bin/bash

# Configuración
DISPLAY_LEN=35        # Caracteres máximos a mostrar
TICK=0.30             # Frecuencia de actualización en segundos (300ms)
WAIT_TICKS=10         # Ticks de espera inicial (10 * 0.3s = 3s)
CHECK_INTERVAL=3      # Cada cuántos ticks consultamos playerctl (3 * 0.3s = 0.9s)

# Variables de estado
last_raw=""
song_text=""
scroll_pos=0
wait_cnt=$WAIT_TICKS
tick_cnt=0
status_playing="false"

# Formatear caracteres especiales para Pango (Waybar usa marcado Pango)
escape_pango() {
    local val="$1"
    val="${val//&/&amp;}"
    val="${val//</&lt;}"
    val="${val//>/&gt;}"
    echo "$val"
}

get_player_data() {
    # Obtener estado en una sola llamada usando ';' como delimitador
    playerctl metadata --format '{{status}};{{playerName}};{{artist}};{{title}}' 2>/dev/null
}

# Bucle infinito para streaming en Waybar
while true; do
    # Cada CHECK_INTERVAL ticks, o si es la primera vez, actualizamos los datos de playerctl
    if [ $((tick_cnt % CHECK_INTERVAL)) -eq 0 ] || [ -z "$last_raw" ]; then
        raw=$(get_player_data)
        if [ -z "$raw" ]; then
            # No hay música sonando
            echo ""
            last_raw=""
            sleep 2
            tick_cnt=0
            continue
        fi

        if [ "$raw" != "$last_raw" ]; then
            # Ha cambiado la canción o el estado de reproducción
            last_raw="$raw"
            
            # Separar los datos
            IFS=';' read -r status player artist title <<< "$raw"
            
            # Determinar el icono de reproducción
            case "$player" in
                spotify*) icon="♫" ;;
                *)        icon="▶" ;;
            esac
            [ "$status" = "Paused" ] && icon="⏸"
            
            # Construir texto de la canción
            if [ -n "$artist" ] && [ -n "$title" ]; then
                full_text="$artist · $title"
            elif [ -n "$title" ]; then
                full_text="$title"
            else
                full_text="$artist"
            fi
            
            # Limpiar espacios en blanco al inicio/final
            full_text=$(echo "$full_text" | xargs)
            song_text="$icon  $full_text"
            
            # Reiniciar scroll y espera
            scroll_pos=0
            wait_cnt=$WAIT_TICKS
            status_playing=$([ "$status" = "Playing" ] && echo "true" || echo "false")
        fi
    fi

    # Si está en pausa, mostramos el texto recortado pero fijo (sin scroll)
    if [ "$status_playing" != "true" ]; then
        text_to_show="${song_text:0:$DISPLAY_LEN}"
        if [ ${#song_text} -gt $DISPLAY_LEN ]; then
            text_to_show="${text_to_show}..."
        fi
        echo "$(escape_pango "$text_to_show")"
        sleep 1
        tick_cnt=0
        last_raw="" # Forzar actualización en la próxima iteración
        continue
    fi

    # Lógica de scroll para reproducción activa
    len=${#song_text}
    if [ $len -le $DISPLAY_LEN ]; then
        # Si cabe completo en el límite, se muestra fijo sin scroll
        echo "$(escape_pango "$song_text")"
    else
        # Si es más largo, aplicamos el efecto marquesina (scroll)
        padding="   ·   "
        extended_text="${song_text}${padding}"
        ext_len=${#extended_text}
        
        if [ $wait_cnt -gt 0 ]; then
            # Espera inicial de 3 segundos al principio de la canción
            text_to_show="${song_text:0:$DISPLAY_LEN}"
            wait_cnt=$((wait_cnt - 1))
        else
            # Calcular la ventana deslizante sobre el texto extendido
            if [ $((scroll_pos + DISPLAY_LEN)) -gt $ext_len ]; then
                # El scroll se sale por el final, concatenamos el principio para que sea fluido
                overflow=$((scroll_pos + DISPLAY_LEN - ext_len))
                part1="${extended_text:$scroll_pos}"
                part2="${extended_text:0:$overflow}"
                text_to_show="${part1}${part2}"
            else
                text_to_show="${extended_text:$scroll_pos:$DISPLAY_LEN}"
            fi
            
            scroll_pos=$((scroll_pos + 1))
            if [ $scroll_pos -ge $ext_len ]; then
                # Al completar una vuelta, reiniciamos el scroll y esperamos de nuevo
                scroll_pos=0
                wait_cnt=$WAIT_TICKS
            fi
        fi
        echo "$(escape_pango "$text_to_show")"
    fi

    sleep $TICK
    tick_cnt=$((tick_cnt + 1))
done
