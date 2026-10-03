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

        M_UNI="<span color='#9ece6a'>󰂑</span>  <b>Modo Uni (Silencioso)</b>    <span color='#787c99'>[60Hz · 0 RPM · Eco]</span>"
        M_NORMAL="<span color='#7aa2f7'>󰓅</span>  <b>Modo Normal (Equilibrado)</b> <span color='#787c99'>[144Hz · Blur · Balance]</span>"
        M_GAMER="<span color='#f7768e'>󰊴</span>  <b>Modo Gamer (Máximo)</b>     <span color='#ff9e64'>[144Hz · Turbo · No Blur]</span>"
        M_AUTO="<span color='#bb9af7'>󰑓</span>  <b>Modo Automático</b>         <span color='#787c99'>[Uni en la uni · según cargador]</span>"

        CHOICE=$(printf "%b\n%b\n%b\n%b" "$M_UNI" "$M_NORMAL" "$M_GAMER" "$M_AUTO" | \
            rofi -dmenu \
                 -p "󰓅 Modos" \
                 -theme "$ROFI_THEME" \
                 -no-custom \
                 -markup-rows \
                 -hover-select \
                 -me-select-entry '' \
                 -me-accept-entry 'MousePrimary' \
                 -cache-file /dev/null)

        case "$CHOICE" in
            *"Uni"*)    apply_uni ;;
            *"Normal"*) apply_normal ;;
            *"Gamer"*)  apply_gamer ;;
            *"Automático"*) apply_auto ;;
        esac
        ;;
esac
