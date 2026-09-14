#!/bin/bash
# Lanza fastfetch eligiendo el logo segun el ancho real de la terminal,
# para que el dibujo no salga cortado si la ventana esta partida/estrecha.

cols=$(tput cols)

if (( cols < 60 )); then
    exec fastfetch --logo none
elif (( cols < 100 )); then
    exec fastfetch --logo arch_small --logo-padding-top 6
else
    exec fastfetch
fi
