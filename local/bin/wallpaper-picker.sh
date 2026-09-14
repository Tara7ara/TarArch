#!/bin/bash
# =============================================================================
# SELECTOR VISUAL DE WALLPAPERS (TARARCH)
# =============================================================================

WALLPAPER_DIR="$HOME/img/wallpapers"
CACHE_FILE="$HOME/.cache/current_wallpaper"

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Wallpapers" "Directorio no encontrado: $WALLPAPER_DIR"
    exit 1
fi

# Generar lista con miniaturas para Rofi
menu_items=""
while IFS= read -r file; do
    [ -z "$file" ] && continue
    base=$(basename "$file")
    menu_items+="${base}\0icon\x1f${file}\n"
done < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.jpeg" \) | sort)

selected_base=$(echo -en "$menu_items" | rofi -dmenu -theme ~/.config/rofi/wallpaper.rasi -p "󰸉 Fondos")

if [ -n "$selected_base" ]; then
    selected_file="$WALLPAPER_DIR/$selected_base"
    if [ -f "$selected_file" ]; then
        if ! pgrep -x awww-daemon > /dev/null; then
            awww-daemon &
            sleep 0.2
        fi
        awww img "$selected_file" --transition-type fade --transition-duration 0.5 --transition-fps 144 --filter Lanczos3
        echo "$selected_file" > "$CACHE_FILE"
        ln -sf "$selected_file" "$HOME/.cache/current_wallpaper_lock.png"
        notify-send "Fondo de Pantalla" "Fondo aplicado con éxito"
    fi
fi
