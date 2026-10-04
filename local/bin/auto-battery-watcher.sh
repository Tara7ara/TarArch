#!/bin/bash
# =============================================================================
# AUTO BATTERY WATCHER — TARARCH
# Elige el modo según cargador + ubicación (la escribe auto-network-watcher.sh):
#   en la uni       -> uni (enchufada o no)
#   resto, batería  -> uni (60Hz)
#   resto, enchufada-> normal (144Hz)
# Si eliges un modo a mano (set-system-mode.sh), ese manda hasta "modos auto".
# =============================================================================

AC_FILE="/sys/class/power_supply/AC0/online"
[ ! -f "$AC_FILE" ] && exit 1

MODE_CACHE="$HOME/.cache/current_system_mode"
LOCATION_FILE="/run/user/$(id -u)/network-location"
MANUAL_FLAG="/run/user/$(id -u)/system-mode-manual"
RECHECK_FLAG="/run/user/$(id -u)/system-mode-recheck"
SET_MODE="$HOME/.local/bin/set-system-mode.sh"
LAST_STATE=""
FIRST_RUN=1

# Al arrancar, esperar (máx. 15s) a saber la ubicación para no poner
# normal y a los pocos segundos uni si se arranca en la uni enchufada
for _ in $(seq 15); do
    [ -f "$LOCATION_FILE" ] && break
    sleep 1
done

while true; do
    AC=$(cat "$AC_FILE" 2>/dev/null)
    LOCATION=$(cat "$LOCATION_FILE" 2>/dev/null)
    STATE="$AC:$LOCATION"

    # "modos auto" pide reevaluar aunque no haya cambiado nada
    if [ -f "$RECHECK_FLAG" ]; then
        rm -f "$RECHECK_FLAG"
        LAST_STATE=""
    fi

    if [ "$STATE" != "$LAST_STATE" ]; then
        TARGET=""
        if [ "$LOCATION" = "uni" ] || [ "$AC" = "0" ]; then
            TARGET="uni"
        elif [ "$AC" = "1" ]; then
            TARGET="normal"
        fi

        # Modo fijado a mano: no se toca. Solo al arrancar la sesión se reaplica
        # el que había, porque el refresco de hyprctl no sobrevive a un reinicio
        # de Hyprland.
        if [ -f "$MANUAL_FLAG" ]; then
            TARGET=""
            if [ "$FIRST_RUN" = "1" ]; then
                CURRENT=$(cat "$MODE_CACHE" 2>/dev/null)
                [ -n "$CURRENT" ] && SYSTEM_MODE_AUTO=1 "$SET_MODE" "$CURRENT"
            fi
        fi

        # Al arrancar la sesión, hyprctl keyword de una sesión anterior ya no
        # existe (no persiste entre reinicios de Hyprland), así que el caché
        # de modo puede estar desincronizado del refresh rate real: forzamos
        # reaplicar siempre en el primer chequeo, sin fiarnos del caché.
        # En cambios posteriores (sesión ya viva) sí respetamos el caché
        # para evitar el popup fantasma si ya estabas en ese modo.
        if [ -n "$TARGET" ]; then
            if [ "$FIRST_RUN" = "1" ] || [ "$(cat "$MODE_CACHE" 2>/dev/null)" != "$TARGET" ]; then
                SYSTEM_MODE_AUTO=1 "$SET_MODE" "$TARGET"
            fi
        fi
        LAST_STATE="$STATE"
        FIRST_RUN=0
    fi

    sleep 3
done
