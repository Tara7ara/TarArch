#!/bin/bash
# Establece una imagen como fondo de pantalla sincronizando cursor y pantalla de bloqueo
IMAGE="$1"
[ ! -f "$IMAGE" ] && exit 1

if ! pgrep -x awww-daemon > /dev/null; then
    awww-daemon &
    sleep 0.5
fi

awww img "$IMAGE" --transition-type fade --transition-duration 0.4 --transition-fps 144 --filter Lanczos3
echo "$IMAGE" > "$HOME/.cache/current_wallpaper"
ln -sf "$IMAGE" "$HOME/.cache/current_wallpaper_lock.png"
notify-send "Fondo de Pantalla" "Fondo y bloqueo actualizados" -i "$IMAGE"
