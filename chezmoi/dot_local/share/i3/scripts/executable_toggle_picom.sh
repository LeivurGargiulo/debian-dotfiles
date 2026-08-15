#!/bin/bash
if pgrep -x picom > /dev/null; then
    pkill picom
    notify-send -t 1500 "picom" "compositor off"
else
    picom --config ~/.config/picom/i3.conf -b
    notify-send -t 1500 "picom" "compositor on"
fi
