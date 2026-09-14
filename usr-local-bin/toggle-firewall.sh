#!/bin/bash
if sudo -n nft list table inet filter &>/dev/null; then
    sudo -n nft flush ruleset
    notify-send "Firewall" "nftables desactivado"
else
    sudo -n nft -f /etc/nftables.conf
    notify-send "Firewall" "nftables activo"
fi
