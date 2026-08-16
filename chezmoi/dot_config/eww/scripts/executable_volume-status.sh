#!/bin/bash
# One-shot volume/mute reader for eww's defpoll (Task 2). Not a daemon —
# invoked fresh on each poll tick while the volume popup is visible.

vol_raw=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null)
mute_raw=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)

vol=$(echo "$vol_raw" | grep -oP '\d+(?=%)' | head -1)
[ -z "$vol" ] && vol=0

if echo "$mute_raw" | grep -q "yes"; then
    muted=true
else
    muted=false
fi

python3 -c "import json, sys; print(json.dumps({'volume': int(sys.argv[1]), 'muted': sys.argv[2] == 'true'}))" "$vol" "$muted"
