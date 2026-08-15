#!/bin/bash

lock="  Lock"
logout="󰗽  Logout"
reboot="  Reboot"
shutdown="  Shutdown"

options="$lock\n$logout\n$reboot\n$shutdown"

selected_option=$(echo -e "$options" | rofi -dmenu -i -p "Power" -config ~/.config/rofi/config.rasi)

case "$selected_option" in
    "$lock")
        ~/.local/share/i3/scripts/lock.sh
        ;;
    "$logout")
        i3-msg exit
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$shutdown")
        systemctl poweroff
        ;;
esac
