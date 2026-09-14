#!/bin/bash
if systemctl --user is-active --quiet bt-proximity-lock.service; then
    systemctl --user stop bt-proximity-lock.service
    rm -f /tmp/bt-proximity-status
    notify-send "Bloqueo por proximidad" "Desactivado"
else
    systemctl --user start bt-proximity-lock.service
    notify-send "Bloqueo por proximidad" "Activado"
fi
