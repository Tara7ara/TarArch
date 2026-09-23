#!/bin/bash
# Alterna la ventana entre flotante compacta centrada y fija (Super + G)

IS_FLOATING=$(hyprctl activewindow -j | jq -r '.floating')

if [ "$IS_FLOATING" = "true" ]; then
    hyprctl dispatch togglefloating
else
    hyprctl dispatch togglefloating
    hyprctl dispatch resizeactive exact 800 520
    hyprctl dispatch centerwindow
fi
