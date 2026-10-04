#!/usr/bin/env bash
# En el inicio de sesión, da a Hyprlock un segundo para cubrir la pantalla
# antes de iniciar el daemon y dibujar el fondo del escritorio.

"$HOME/.local/bin/hyprlock-launch.sh" &
sleep 1

awww-daemon &

# Espera a que el socket de awww esté listo antes de pedirle la imagen.
for _ in {1..30}; do
    if awww query >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

WALL=$(cat "$HOME/.cache/current_wallpaper" 2>/dev/null)
[ -f "$WALL" ] || WALL="$HOME/.config/hypr/icons/fondo-bloqueo.png"

awww img "$WALL" \
    --transition-type fade \
    --transition-duration 0.4 \
    --transition-fps 144 \
    --filter Lanczos3
