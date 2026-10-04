#!/bin/bash
# Lanzador rápido de conexiones SSH (TaraNAS / Servidor)
source $HOME/.local/bin/rofi-row.sh

IDX=$( { rofi_row "󰒋" "TaraNAS" "almacenamiento"
         rofi_row "󰒍" "Servidor" "servicios de casa"; } | \
    rofi -dmenu -format i \
         -p "󰣀" \
         -theme ~/.config/rofi/ssh-menu.rasi \
         -no-custom \
         -markup-rows \
         -hover-select \
         -me-select-entry '' \
         -me-accept-entry 'MousePrimary' \
         -cache-file /dev/null)

case "$IDX" in
    0) kitty --title "SSH TaraNAS" sh -c "ssh nas; exec \$SHELL" ;;
    1) kitty --title "SSH Servidor" sh -c "ssh servidor; exec \$SHELL" ;;
esac
