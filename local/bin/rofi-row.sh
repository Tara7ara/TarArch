#!/bin/bash
# =============================================================================
# Formato común de las filas de los menús rofi de TarArch.
#   rofi_row ICONO TEXTO [DETALLE] [activo]
# Icono en gris (naranja si la fila es la opción activa), texto claro y el
# detalle pequeño y en gris detrás. Sin negritas ni colores por fila.
# =============================================================================

rofi_escape() {
    local s="$1"
    s=${s//&/&amp;}; s=${s//</&lt;}; s=${s//>/&gt;}
    printf '%s' "$s"
}

rofi_row() {
    local icon="$1" text detail="" color="#6e6e6e"
    text=$(rofi_escape "$2")
    [ -n "$3" ] && detail="   <span size='9.5pt' foreground='#6e6e6e'>$(rofi_escape "$3")</span>"
    [ -n "$4" ] && color="#ff9e64"
    printf "<span foreground='%s'>%s</span>   <span foreground='#d6d6d6'>%s</span>%s\n" \
        "$color" "$icon" "$text" "$detail"
}
