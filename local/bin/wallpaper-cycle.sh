#!/bin/bash
WALLPAPER_DIR="$HOME/img/wallpapers"
CURRENT_FILE="$HOME/.cache/current_wallpaper"

mapfile -t WALLS < <(find "$WALLPAPER_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.webp" \) | sort)

if [ ${#WALLS[@]} -eq 0 ]; then
    exit 1
fi

CURRENT=$(cat "$CURRENT_FILE" 2>/dev/null)
CURRENT_INDEX=-1

for i in "${!WALLS[@]}"; do
    if [ "${WALLS[$i]}" = "$CURRENT" ]; then
        CURRENT_INDEX=$i
        break
    fi
done

if [ "$1" = "next" ]; then
    NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ${#WALLS[@]} ))
elif [ "$1" = "prev" ]; then
    NEXT_INDEX=$(( (CURRENT_INDEX - 1 + ${#WALLS[@]}) % ${#WALLS[@]} ))
else
    NEXT_INDEX=0
fi

NEXT_WALL="${WALLS[$NEXT_INDEX]}"
if ! pgrep -x awww-daemon > /dev/null; then
    awww-daemon &
    sleep 0.5
fi
awww img "$NEXT_WALL" --transition-type fade --transition-duration 0.4 --transition-fps 144 --filter Lanczos3
echo "$NEXT_WALL" > "$CURRENT_FILE"
ln -sf "$NEXT_WALL" "$HOME/.cache/current_wallpaper_lock.png"
