#!/bin/bash
CACHE_A="$HOME/.cache/hyprlock/art_a.jpg"
CACHE_B="$HOME/.cache/hyprlock/art_b.jpg"
ACTIVE_FILE="$HOME/.cache/hyprlock/active_art.txt"
BLANK="$HOME/.local/share/hyprlock/transparent.png"
PIDFILE="/tmp/hyprlock-art-watcher.pid"

# Función de limpieza para matar todos los procesos hijos al salir
cleanup() {
    echo "$(date): Watcher exiting, cleaning up child processes..."
    # Matar los procesos hijos de esta shell (incluyendo el loop y playerctl)
    pkill -P $$ 2>/dev/null
    # Eliminar el pidfile si somos nosotros los que lo creamos
    if [ -f "$PIDFILE" ] && [ "$(cat "$PIDFILE")" -eq "$$" ]; then
        rm -f "$PIDFILE" 2>/dev/null
    fi
    exit 0
}
# Capturar señales de terminación para no dejar procesos huérfanos
trap cleanup SIGINT SIGTERM EXIT

# Control de instancia única mediante PID file con fallback de kill -9 si se atasca
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "$(date): Killing old watcher instance ($OLD_PID)..."
        kill "$OLD_PID" 2>/dev/null
        sleep 0.2
        # Si sigue vivo después de SIGTERM (por el bloqueo de primer plano de bash), forzar muerte
        if kill -0 "$OLD_PID" 2>/dev/null; then
            echo "$(date): Old watcher ($OLD_PID) did not exit. Forcing with SIGKILL..."
            kill -9 "$OLD_PID" 2>/dev/null
        fi
    fi
fi
echo "$$" > "$PIDFILE"

echo "$(date): Watcher script invoked"

update_art() {
    local ART="$1"
    echo "$(date): update_art called with URL: $ART"

    local CURRENT=""
    [ -f "$ACTIVE_FILE" ] && CURRENT=$(cat "$ACTIVE_FILE")
    local TARGET=""
    [ "$CURRENT" = "$CACHE_A" ] && TARGET="$CACHE_B" || TARGET="$CACHE_A"
    
    echo "Current active file: $CURRENT"
    echo "Target cache file: $TARGET"

    # Verificar qué reproductor está activo
    local PLAYER=$(playerctl metadata --format "{{playerName}}" 2>/dev/null)
    echo "Active player: $PLAYER"

    # Solo Spotify muestra la portada del álbum. Si es YouTube u otro, usar la transparente
    if [ "$PLAYER" != "spotify" ]; then
        echo "Player is not spotify ($PLAYER), using blank cover"
        cp "$BLANK" "${TARGET}.tmp" && mv "${TARGET}.tmp" "$TARGET"
    elif [ -z "$ART" ]; then
        echo "URL is empty, clearing cover (using blank)"
        cp "$BLANK" "${TARGET}.tmp" && mv "${TARGET}.tmp" "$TARGET"
    elif [[ "$ART" == http* ]]; then
        echo "Downloading via curl..."
        # Descarga a archivo temporal
        curl -s --max-time 4 -o "${TARGET}.tmp" "$ART" 2>/dev/null
        CURL_STATUS=$?
        if [ $CURL_STATUS -ne 0 ]; then
            echo "curl failed with code $CURL_STATUS, copying blank"
            rm -f "${TARGET}.tmp" 2>/dev/null
            cp "$BLANK" "${TARGET}.tmp" && mv "${TARGET}.tmp" "$TARGET"
        else
            echo "curl succeeded, moving to target"
            mv "${TARGET}.tmp" "$TARGET"
        fi
    elif [[ "$ART" == file://* ]]; then
        echo "Copying local file..."
        cp "${ART#file://}" "${TARGET}.tmp" 2>/dev/null && mv "${TARGET}.tmp" "$TARGET" || (cp "$BLANK" "${TARGET}.tmp" && mv "${TARGET}.tmp" "$TARGET")
    else
        echo "Invalid format, copying blank"
        cp "$BLANK" "${TARGET}.tmp" && mv "${TARGET}.tmp" "$TARGET"
    fi

    # Escritura atómica usando un archivo temporal y renombrándolo
    echo "$TARGET" > "${ACTIVE_FILE}.tmp" && mv "${ACTIVE_FILE}.tmp" "$ACTIVE_FILE"
    echo "Updated active_art.txt to: $TARGET"
    
    # Mandar señal USR2 para actualizar hyprlock de inmediato
    pkill -x -USR2 hyprlock
    echo "Sent USR2 to hyprlock"
}

# Bucle en segundo plano para que la shell responda inmediatamente a las señales (wait se interrumpe por traps)
run_playerctl_loop() {
    echo "$(date): Starting playerctl follow loop"
    while true; do
        stdbuf -oL playerctl --follow metadata --format "{{mpris:artUrl}}" 2>/dev/null | while read -r ART; do
            echo "$(date): playerctl output: $ART"
            update_art "$ART"
        done
        echo "$(date): playerctl exited, sleeping 1s before restart"
        sleep 1
    done
}

run_playerctl_loop &
LOOP_PID=$!

# Esperar con wait para poder recibir señales
wait "$LOOP_PID"
