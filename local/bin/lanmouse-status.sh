#!/bin/bash
if pgrep -x lan-mouse > /dev/null; then
    echo '{"text":"󰢹","class":"kvm-on","tooltip":"KVM activo — W11 192.168.1.20"}'
else
    echo '{"text":"󰢹","class":"kvm-off","tooltip":"KVM inactivo"}'
fi
