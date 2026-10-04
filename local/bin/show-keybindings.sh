#!/bin/bash
# =============================================================================
# VISOR Y LANZADOR DE ATAJOS Y COMANDOS — TARARCH (SUPER + A)
# Enter ejecuta la acción de la fila. Datos y despachador viven en
# keybindings-lib.sh (compartido con la pestaña "Comandos" de Super+Espacio).
# =============================================================================

source $HOME/.local/bin/keybindings-lib.sh

IDX=$(render_keybindings | rofi -dmenu -i -markup-rows -format i -no-custom -selected-row 1 \
    -p "󰌌" -theme ~/.config/rofi/keybindings.rasi)

[ -n "$IDX" ] || exit 0
ENTRY=${KEYBINDINGS_LIST[$IDX]}
[[ $ENTRY == "# "* ]] && exit 0
dispatch_keybinding "${ENTRY%%|*}"
