#!/bin/bash
# Abre GNOME Calendar con el CalDAV (Radicale)

if command -v gnome-calendar &>/dev/null; then
    gnome-calendar &
else
    kitty --title "Instalador de Calendario" bash -c "echo -e '\033[1;33m[TarArch] Instalando GNOME Calendar...\033[0m\n'; sudo pacman -S --needed gnome-calendar; echo -e '\n\033[1;32m✔ Instalación completada. Abriendo calendario...\033[0m'; sleep 1; gnome-calendar &" &
fi
