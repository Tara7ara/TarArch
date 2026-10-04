#!/bin/bash
# Sincroniza el fondo de pantalla actual y lanza Hyprlock
wall=$(cat "$HOME/.cache/current_wallpaper" 2>/dev/null)
# Si aún no se ha elegido fondo, negro liso (viene con el repo)
[ -f "$wall" ] || wall="$HOME/.config/hypr/icons/fondo-bloqueo.png"
ln -sf "$wall" "$HOME/.cache/current_wallpaper_lock.png"

pidof hyprlock || hyprlock
