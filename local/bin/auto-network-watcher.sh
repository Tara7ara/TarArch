#!/bin/bash
# =============================================================================
# AUTO NETWORK WATCHER — TARARCH
# Aplica red-casa o red-fuera según dónde estés conectada (cable o WiFi).
# Ubicación = MAC del gateway de la ruta por defecto (o SSID en la uni):
#   casa  -> red-casa  (DNS AdGuard)
#   uni   -> red-fuera (DNS de la red) + modo uni (lo aplica auto-battery-watcher.sh)
#   fuera -> red-fuera
# La ubicación queda en $LOCATION_FILE para que la lea el watcher de batería.
# Solo actúa al CAMBIAR de red, nunca en bucle. Si eliges un perfil a mano
# (red-casa / red-fuera), ese manda hasta que ejecutes red-auto.
# =============================================================================

HOME_GW_MAC="AA:BB:CC:DD:EE:03"   # Router de casa
UNI_GW_MAC="AA:BB:CC:DD:EE:04"    # Gateway de la otra red
UNI_SSIDS="MiRed MiRed_INVITADOS"  # SSIDs de la otra red
VPN_IFACE="Portatil"
CACHE_FILE="$HOME/.cache/current_network_profile"
MANUAL_FLAG="/run/user/$(id -u)/network-profile-manual"
RECHECK_FLAG="/run/user/$(id -u)/network-profile-recheck"
LOCATION_FILE="/run/user/$(id -u)/network-location"

LAST_LOCATION=""

# Devuelve "casa", "uni", "fuera" o "" (sin red / gateway aún sin resolver)
detect_location() {
    local route gw dev mac ssid
    route=$(ip -4 route show default | grep -v "dev $VPN_IFACE" | head -n1)
    gw=$(awk '{for(i=1;i<=NF;i++) if($i=="via") print $(i+1)}' <<< "$route")
    dev=$(awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' <<< "$route")
    [ -z "$gw" ] || [ -z "$dev" ] && return

    mac=$(ip neigh show "$gw" dev "$dev" | awk '/lladdr/{print $3}')
    if [ -z "$mac" ]; then
        # Entrada ARP aún vacía: un ping la rellena
        ping -c1 -W1 -I "$dev" "$gw" >/dev/null 2>&1
        mac=$(ip neigh show "$gw" dev "$dev" | awk '/lladdr/{print $3}')
    fi
    [ -z "$mac" ] && return

    mac="${mac,,}"
    if [ "$mac" = "$HOME_GW_MAC" ]; then echo "casa"; return; fi
    if [ "$mac" = "$UNI_GW_MAC" ]; then echo "uni"; return; fi
    ssid=$(nmcli -t -f ACTIVE,SSID dev wifi list ifname "$dev" --rescan no 2>/dev/null | sed -n 's/^yes://p' | head -n1)
    if [ -n "$ssid" ] && [[ " $UNI_SSIDS " == *" $ssid "* ]]; then echo "uni"; return; fi
    echo "fuera"
}

# ¿Está ya aplicado el perfil de esta ubicación? (caché + conexión real del cable)
profile_applied() {
    local target="$1" eth_con
    [ "$(cat "$CACHE_FILE" 2>/dev/null)" = "$target" ] || return 1
    eth_con=$(nmcli -g GENERAL.CONNECTION dev show eno2 2>/dev/null | head -n1)
    case "$target" in
        casa)  [ "$eth_con" = "Fuera" ] && return 1 ;;
        fuera) [ "$eth_con" = "Casa Cable" ] && return 1 ;;
    esac
    return 0
}

while true; do
    LOCATION=$(detect_location)

    # red-auto pide reevaluar aunque no haya cambiado la red
    if [ -f "$RECHECK_FLAG" ]; then
        rm -f "$RECHECK_FLAG"
        LAST_LOCATION=""
    fi

    if [ -n "$LOCATION" ] && [ "$LOCATION" != "$LAST_LOCATION" ]; then
        echo "$LOCATION" > "$LOCATION_FILE"
        PROFILE="fuera"; [ "$LOCATION" = "casa" ] && PROFILE="casa"
        if [ ! -f "$MANUAL_FLAG" ] && ! profile_applied "$PROFILE"; then
            RED_AUTO=1 "/home/tara/.local/bin/red-$PROFILE"
        fi
        # En la uni, VPN arriba salvo que la hayas apagado a mano
        # (toggle-vpn.sh deja vpn-manual-off al apagarla)
        if [ "$LOCATION" = "uni" ] && [ ! -f "/run/user/$(id -u)/vpn-manual-off" ] \
           && ! ip link show "$VPN_IFACE" 2>/dev/null | grep -q "UP"; then
            /usr/local/bin/toggle-vpn.sh
        fi
        LAST_LOCATION="$LOCATION"
    fi

    sleep 3
done
