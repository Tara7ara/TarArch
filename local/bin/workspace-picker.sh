#!/bin/bash
CHOICE=$(printf "1\n2\n3\n4\n5\n6\n7\n8\n9" | rofi -dmenu \
    -p "Mover a escritorio" \
    -theme /home/tara/.config/rofi/launcher.rasi \
    -no-fixed-num-lines 2>/dev/null)

[ -z "$CHOICE" ] && exit 0
hyprctl dispatch movetoworkspace "$CHOICE"
