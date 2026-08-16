#!/usr/bin/env bash

killall -q polybar
pkill -f mpris-daemon.sh

while pgrep -x polybar >/dev/null; do sleep 1; done

polybar main &
