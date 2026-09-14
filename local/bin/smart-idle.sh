#!/bin/bash
# Suspensión inteligente: bloquea siempre, suspende solo si el sistema está ocioso.
LOAD=$(LC_ALL=C awk '{print $1}' /proc/loadavg)
BUSY_PROCS="claude|python3|python|node|cargo|make|ffmpeg|aria2c|rsync|restic|wget|yay|pacman|agy"

is_busy() {
    awk -v l="$LOAD" 'BEGIN{exit !(l > 0.5)}' && return 0
    pgrep -fE "$BUSY_PROCS" &>/dev/null && return 0
    return 1
}

if is_busy; then
    # Sistema ocupado: bloquear pantalla y apagarla, pero NO suspender
    hyprlock &
    sleep 0.8
    hyprctl dispatch dpms off
else
    # Sistema inactivo: bloquear y suspender
    hyprlock &
    sleep 1
    systemctl suspend
fi
