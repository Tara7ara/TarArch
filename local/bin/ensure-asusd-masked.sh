#!/bin/bash
# asusd pisa el color/brillo del teclado que pone rogauracore, así que se
# asegura que siga enmascarado. Lo llaman los scripts del teclado (como root).
if systemctl is-active --quiet asusd 2>/dev/null || [ "$(systemctl is-enabled asusd 2>/dev/null)" != "masked" ]; then
    systemctl stop asusd 2>/dev/null
    systemctl mask asusd 2>/dev/null
    notify-send "Teclado ROG" "asusd se habia reactivado y pisaba el color/brillo - desactivado otra vez" -i dialog-warning 2>/dev/null
fi
