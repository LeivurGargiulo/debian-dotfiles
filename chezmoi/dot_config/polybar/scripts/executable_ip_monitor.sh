#!/bin/bash
# Polybar module: public IP + VPN indicator, polled every 5 minutes.

vpn_icon() {
    if ip link | grep -qE '^[0-9]+: .*(tun|wg|tap)'; then
        echo "󰌾"
    else
        echo "󰩠"
    fi
}

while true; do
    ip=$(curl -s --connect-timeout 2 https://api.ipify.org || echo "offline")
    echo "%{F#89dceb}$(vpn_icon)%{F-} ${ip}"
    sleep 300
done
