#!/usr/bin/env bash

killall -q polybar
pkill -f mpris-daemon.sh
eww kill 2>/dev/null
while pgrep -x eww >/dev/null; do sleep 0.2; done

while pgrep -x polybar >/dev/null; do sleep 1; done

eww daemon
# ponytail: fixed 0.5s wait for the daemon socket, no retry loop — fine
# for a login-time launch script, revisit if `eww open` below ever races.
sleep 0.5
eww open nowplaying-popup

polybar main &
