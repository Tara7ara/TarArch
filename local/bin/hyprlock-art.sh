#!/bin/bash
ACTIVE_FILE="$HOME/.cache/hyprlock/active_art.txt"
BLANK="$HOME/.local/share/hyprlock/transparent.png"

if [ -f "$ACTIVE_FILE" ]; then
    CACHE=$(cat "$ACTIVE_FILE")
    [ -f "$CACHE" ] && echo "$CACHE" || echo "$BLANK"
else
    echo "$BLANK"
fi
