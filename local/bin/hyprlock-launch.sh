#!/bin/bash
# Sincroniza el fondo de pantalla actual y lanza Hyprlock
wall=$(cat "$HOME/.cache/current_wallpaper" 2>/dev/null || echo "$HOME/img/wallpapers/arch_default.png")
[ -f "$wall" ] && ln -sf "$wall" "$HOME/.cache/current_wallpaper_lock.png"

pidof hyprlock || hyprlock
