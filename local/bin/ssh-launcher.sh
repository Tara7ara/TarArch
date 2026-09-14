#!/bin/bash
# Lanzador rápido de conexiones SSH (TaraNAS / Servidor)

OPT1="<span color='#ff9e64'>󰒋</span>  <b>TaraNAS</b>        <span color='#787c99'>(Almacenamiento NAS)</span>"
OPT2="<span color='#bb9af7'>󰣀</span>  <b>Servidor</b>       <span color='#787c99'>(Servicios Linux)</span>"

CHOICE=$(printf "%b\n%b" "$OPT1" "$OPT2" | \
    rofi -dmenu \
         -p "󰣀 " \
         -theme ~/.config/rofi/ssh-menu.rasi \
         -no-custom \
         -markup-rows \
         -hover-select \
         -me-select-entry '' \
         -me-accept-entry 'MousePrimary' \
         -cache-file /dev/null)

case "$CHOICE" in
    *"TaraNAS"*)  kitty --title "SSH TaraNAS" sh -c "ssh nas; exec \$SHELL" ;;
    *"Servidor"*) kitty --title "SSH Servidor" sh -c "ssh servidor; exec \$SHELL" ;;
esac
