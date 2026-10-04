#!/bin/bash
# Wrapper de compatibilidad hacia set-system-mode.sh
if [ "$1" = "battery" ] || [ "$1" = "ahorro" ] || [ "$1" = "uni" ]; then
    $HOME/.local/bin/set-system-mode.sh uni
elif [ "$1" = "performance" ] || [ "$1" = "normal" ]; then
    $HOME/.local/bin/set-system-mode.sh normal
elif [ "$1" = "gamer" ]; then
    $HOME/.local/bin/set-system-mode.sh gamer
else
    $HOME/.local/bin/set-system-mode.sh
fi
