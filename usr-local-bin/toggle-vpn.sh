#!/bin/bash
WG_INTERFACE="Portatil"
FLAG="/run/user/$(id -u)/vpn-manual-off"

if ip link show "$WG_INTERFACE" &>/dev/null && ip link show "$WG_INTERFACE" | grep -q "UP"; then
    if nmcli connection down "$WG_INTERFACE"; then
        touch "$FLAG"
        notify-send "VPN" "Desconectada" --icon=network-vpn-disconnected
    else
        notify-send "VPN" "Error al desconectar - revisa journalctl/nmcli" --icon=dialog-error -u critical
    fi
else
    # DNS de AdGuard a través del túnel — el router no puede repartirlo por DHCP
    # (tema WAF), así que se fuerza aquí cada vez que se activa la VPN.
    nmcli connection modify "$WG_INTERFACE" ipv4.dns "192.168.1.10" ipv4.dns-priority -10

    if nmcli connection up "$WG_INTERFACE"; then
        rm -f "$FLAG"
        notify-send "VPN" "Conectada (DNS AdGuard aplicado)" --icon=network-vpn
    else
        notify-send "VPN" "Error al conectar - revisa journalctl/nmcli (¿kernel/módulos desincronizados? prueba a reiniciar)" --icon=dialog-error -u critical
    fi
fi
