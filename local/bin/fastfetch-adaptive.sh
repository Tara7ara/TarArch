#!/bin/bash
# Lanza fastfetch adaptativo:
# - En Kitty con ventana ancha (>= 75 cols): logo con fundido y filas una a una
#   (fastfetch-anim.py; si falla, fastfetch normal con el logo de config.jsonc)
# - En ventana partida (< 75 cols) o fuera de Kitty: logo ASCII compacto
# - En ventana muy estrecha (< 55 cols): solo texto sin logo

cols=$(tput cols 2>/dev/null || echo 80)

if (( cols < 55 )); then
    exec fastfetch --logo none
elif (( cols < 75 )) || [ -z "$KITTY_WINDOW_ID" ]; then
    exec fastfetch --logo arch_small --logo-padding-top 2 --logo-color-1 '#ff9e64' --logo-color-2 '#ff9e64'
else
    exec $HOME/.local/bin/fastfetch-anim.py
fi
