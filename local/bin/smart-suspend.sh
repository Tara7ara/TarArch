#!/bin/bash
LOAD=$(LC_ALL=C awk '{print $1}' /proc/loadavg)
BUSY_PROCS="claude|python3|python|node|cargo|make|ffmpeg|aria2c|rsync|restic|wget|yay|pacman"

is_busy() {
    awk -v l="$LOAD" 'BEGIN{exit !(l > 0.5)}' && return 0
    pgrep -fE "$BUSY_PROCS" &>/dev/null && return 0
    return 1
}

is_busy || systemctl suspend
