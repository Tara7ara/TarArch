#!/bin/bash
# =============================================================================
# MODO DE SCRIPT ROFI — pestaña "Comandos" del lanzador unificado (Super+Espacio)
# Es el mismo listado y las mismas acciones que Super+A (keybindings-lib.sh),
# pero integrado como pestaña dentro del propio lanzador en vez de una ventana
# aparte. La tecla de cada fila llega en $ROFI_INFO.
# =============================================================================

source $HOME/.local/bin/keybindings-lib.sh

if [ -z "$ROFI_RETV" ] || [ "$ROFI_RETV" = 0 ]; then
    printf '\0markup-rows\x1ftrue\n\0no-custom\x1ftrue\n'
    # Sin la primera cabecera: rofi abre con la fila 0 seleccionada aunque no
    # sea seleccionable, y en modo script no hay forma de moverla al abrir.
    render_keybindings | tail -n +2
    exit 0
fi

# Se lanza cuando rofi ya se ha cerrado, por si la acción abre otro rofi.
( sleep 0.2; dispatch_keybinding "$ROFI_INFO" ) >/dev/null 2>&1 &
