#!/bin/bash
# Polybar module: public IP + VPN indicator, polled every 5 minutes.

vpn_icon() {
    if ip link | grep -qE '^[0-9]+: .*(tun|wg|tap)'; then
        echo "󰌾"
    else
        echo "󰩠"
    fi
}

ip_regex='^[0-9a-fA-F:.]+$'

while true; do
    ip=$(curl -s --connect-timeout 2 https://api.ipify.org)
    [[ "$ip" =~ $ip_regex ]] || ip="offline"
    echo "%{F#ffa057}$(vpn_icon)%{F-} ${ip}"
    sleep 300
done
