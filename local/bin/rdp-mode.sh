#!/bin/bash
# rdp-mode.sh on|off — activa/desactiva el submap "rdp" y el borde de aviso
case "$1" in
    on)
        hyprctl dispatch submap rdp >/dev/null
        hyprctl keyword general:col.active_border "rgba(f38ba8ee)" >/dev/null
        ;;
    off)
        hyprctl dispatch submap reset >/dev/null
        hyprctl keyword general:col.active_border "rgba(ffffff18)" >/dev/null
        ;;
esac
