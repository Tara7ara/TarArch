#!/bin/bash
# Wrapper de compatibilidad hacia set-system-mode.sh
if [ "$1" = "battery" ] || [ "$1" = "ahorro" ] || [ "$1" = "uni" ]; then
    /home/tara/.local/bin/set-system-mode.sh uni
elif [ "$1" = "performance" ] || [ "$1" = "normal" ]; then
    /home/tara/.local/bin/set-system-mode.sh normal
elif [ "$1" = "gamer" ]; then
    /home/tara/.local/bin/set-system-mode.sh gamer
else
    /home/tara/.local/bin/set-system-mode.sh
fi
