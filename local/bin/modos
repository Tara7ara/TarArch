#!/bin/bash
# =============================================================================
# GESTOR CENTRALIZADO DE MODOS DE SISTEMA — TARARCH
# Modos:
#   uni    -> 60Hz · Ventiladores Silenciosos · CPU Eco · LEDs Off
#   normal -> 144Hz · Equilibrado · Efectos Blur y Animaciones · LEDs On
#   gamer  -> 144Hz · CPU Turbo 100% · Sin Blur/Sombras · Máxima Respuesta
# =============================================================================

CACHE_FILE="$HOME/.cache/current_system_mode"
ROFI_THEME="$HOME/.config/rofi/modes.rasi"
# Elegido a mano (no por auto-battery-watcher.sh): ese modo manda hasta "modos auto"
MANUAL_FLAG="/run/user/$(id -u)/system-mode-manual"
RECHECK_FLAG="/run/user/$(id -u)/system-mode-recheck"

mark_origin() {
    [ -z "$SYSTEM_MODE_AUTO" ] && touch "$MANUAL_FLAG"
}

apply_auto() {
    rm -f "$MANUAL_FLAG"
    touch "$RECHECK_FLAG"
    notify-send "Modo Automático" "󰑓 Uni en la uni o con batería · Normal enchufada" -i battery-good
}

apply_uni() {
    mark_origin
    powerprofilesctl set power-saver 2>/dev/null || true
    hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })' >/dev/null 2>&1
    hyprctl eval 'hl.config({ animations = { enabled = true }, decoration = { blur = { enabled = true }, shadow = { enabled = true } } })' >/dev/null 2>&1
    rogauracore single_static 000000 2>/dev/null || true
    echo "uni" > "$CACHE_FILE"
    notify-send "Modo Uni / Ahorro" "󰂑 60Hz · Ventiladores Silenciosos · CPU Eco · LEDs Off" -i battery-low
}

apply_normal() {
    mark_origin
    powerprofilesctl set balanced 2>/dev/null || true
    hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })' >/dev/null 2>&1
    hyprctl eval 'hl.config({ animations = { enabled = true }, decoration = { blur = { enabled = true }, shadow = { enabled = true } } })' >/dev/null 2>&1
    rogauracore white 2>/dev/null || true
    echo "normal" > "$CACHE_FILE"
    notify-send "Modo Normal" "󰓅 144Hz · Equilibrado · Efectos Blur · LEDs On" -i battery-charging
}

apply_gamer() {
    mark_origin
    powerprofilesctl set performance 2>/dev/null || true
    hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })' >/dev/null 2>&1
    hyprctl eval 'hl.config({ animations = { enabled = false }, decoration = { blur = { enabled = false }, shadow = { enabled = false } } })' >/dev/null 2>&1
    rogauracore white 2>/dev/null || true
    echo "gamer" > "$CACHE_FILE"
    notify-send "Modo Gamer" "󰊴 144Hz · CPU Turbo 100% · Sin Blur · Latencia Mínima" -i applications-games
}

case "$1" in
    uni|ahorro|battery|silencioso|1)
        apply_uni
        ;;
    normal|balanced|equilibrado|2)
        apply_normal
        ;;
    gamer|juego|performance|turbo|3)
        apply_gamer
        ;;
    auto|automatico)
        apply_auto
        ;;
    toggle|next|rotar)
        CURRENT=$(cat "$CACHE_FILE" 2>/dev/null)
        case "$CURRENT" in
            "uni")    apply_normal ;;
            "normal") apply_gamer ;;
            *)        apply_uni ;;
        esac
        ;;
    status)
        CURRENT=$(cat "$CACHE_FILE" 2>/dev/null)
        [ -z "$CURRENT" ] && CURRENT="normal"
        echo "$CURRENT"
        ;;
    *)
        CURRENT=$(cat "$CACHE_FILE" 2>/dev/null)
        [ -z "$CURRENT" ] && CURRENT="normal"

        source $HOME/.local/bin/rofi-row.sh
        act() { [ "$CURRENT" = "$1" ] && echo activo; }
        # Se elige por posición: la fila Automático también contiene "Uni".
        IDX=$( { rofi_row "󰂑" "Uni" "60 Hz, ventiladores parados, ahorro" "$(act uni)"
                 rofi_row "󰓅" "Normal" "144 Hz, equilibrado" "$(act normal)"
                 rofi_row "󰊴" "Gamer" "144 Hz, turbo, sin blur" "$(act gamer)"
                 rofi_row "󰑓" "Automático" "uni con batería o en la uni, normal enchufado" "$([ -f "$MANUAL_FLAG" ] || echo activo)"; } | \
            rofi -dmenu -format i \
                 -p "󰓅" \
                 -theme "$ROFI_THEME" \
                 -no-custom \
                 -markup-rows \
                 -hover-select \
                 -me-select-entry '' \
                 -me-accept-entry 'MousePrimary' \
                 -cache-file /dev/null)

        case "$IDX" in
            0) apply_uni ;;
            1) apply_normal ;;
            2) apply_gamer ;;
            3) apply_auto ;;
        esac
        ;;
esac
