#!/bin/bash
# rdp-mode.sh on|off — activa/desactiva el submap "rdp" y el borde de aviso
case "$1" in
    on)
        hyprctl dispatch 'hl.dsp.submap("rdp")' >/dev/null
        hyprctl eval 'hl.config({ ["general.col.active_border"] = "rgba(f38ba8ee)" })' >/dev/null
        ;;
    off)
        hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null
        hyprctl eval 'hl.config({ ["general.col.active_border"] = "rgba(ffffff18)" })' >/dev/null
        ;;
esac
