#!/bin/bash
# Defensa contra el bug de asusd pisando el color/brillo del teclado ROG
# (ver Teclado_LED.md): asusd compite con rogauracore y revierte cualquier
# cambio en ~1s ("reloading keyboard mode" en su journal). Se descubrio que
# algo (asusctl/rog-control-center probablemente) puede desenmascararlo sin
# que nos demos cuenta. Llamado desde apply-kbd-led-state.sh, kbd-color-cycle.sh
# y kbd-brightness.sh - se ejecuta siempre como root (los tres se lanzan con
# sudo o como servicio systemd), asi que systemctl aqui no necesita sudo propio.
if systemctl is-active --quiet asusd 2>/dev/null || [ "$(systemctl is-enabled asusd 2>/dev/null)" != "masked" ]; then
    systemctl stop asusd 2>/dev/null
    systemctl mask asusd 2>/dev/null
    notify-send "Teclado ROG" "asusd se habia reactivado y pisaba el color/brillo - desactivado otra vez" -i dialog-warning 2>/dev/null
fi
