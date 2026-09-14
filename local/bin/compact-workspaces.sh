#!/bin/bash
# Compacta escritorios: 1,4 → 1,2 / 1,3,4 → 1,2,3

ACTIVE=$(WAYLAND_DISPLAY=wayland-1 hyprctl activeworkspace | grep -oP 'workspace ID \K\d+')
WORKSPACES=$(WAYLAND_DISPLAY=wayland-1 hyprctl workspaces | grep -oP 'workspace ID \K\d+' | sort -n)

NEW_NUM=1
for WS_ID in $WORKSPACES; do
    if [ "$WS_ID" -ne "$NEW_NUM" ]; then
        # Obtener direcciones de ventanas en este escritorio
        WINDOWS=$(WAYLAND_DISPLAY=wayland-1 hyprctl clients | awk -v ws="$WS_ID" '
            /^Window / { addr = $2 }
            /workspace: / { if ($2 == ws) print addr }
        ')
        for WIN in $WINDOWS; do
            WAYLAND_DISPLAY=wayland-1 hyprctl dispatch movetoworkspacesilent "$NEW_NUM,address:0x$WIN"
        done
        # Si el usuario estaba en ese escritorio, moverlo también
        if [ "$WS_ID" -eq "$ACTIVE" ]; then
            WAYLAND_DISPLAY=wayland-1 hyprctl dispatch workspace "$NEW_NUM"
        fi
    fi
    NEW_NUM=$((NEW_NUM + 1))
done

notify-send "Escritorios" "Reordenados: 1 - $((NEW_NUM - 1))"
