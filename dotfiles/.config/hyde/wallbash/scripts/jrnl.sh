#!/usr/bin/env bash
# jrnl's colors.{body,date,tags,title} only accept 8 ANSI names + NONE, no
# hex -- see docs/reference-config-file.md upstream. Unlike every other
# tool this repo themes, jrnl.yaml can't be safely generated from scratch:
# it requires a real `journals: default: journal: <path>` entry pointing
# at the user's actual journal, which nothing here knows. So this script
# only *updates the colors key* of an existing config -- if
# ~/.config/jrnl/jrnl.yaml doesn't exist yet (nobody has set up jrnl on
# this machine), it does nothing, same as if the directory didn't exist at
# all (the usual fn_wallbash "skip missing directory" case this repo's
# other themed tools rely on). color.set.sh exports every dcol_* variable
# before running this script.
set -euo pipefail

nearest_ansi() {
    local hex="${1#\#}"
    local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
    local best="RED" best_d=999999
    local -A named=(
        [RED]="255 0 0" [GREEN]="0 255 0" [YELLOW]="255 255 0"
        [BLUE]="0 0 255" [MAGENTA]="255 0 255" [CYAN]="0 255 255"
        [WHITE]="255 255 255" [BLACK]="0 0 0"
    )
    local name rgb nr ng nb d
    for name in "${!named[@]}"; do
        rgb=(${named[$name]})
        nr=${rgb[0]}; ng=${rgb[1]}; nb=${rgb[2]}
        d=$(( (r-nr)*(r-nr) + (g-ng)*(g-ng) + (b-nb)*(b-nb) ))
        if (( d < best_d )); then best_d=$d; best=$name; fi
    done
    echo "$best"
}

conf="${HOME}/.config/jrnl/jrnl.yaml"
[[ -f "$conf" ]] || exit 0

body="$(nearest_ansi "${dcol_txt1:-fcfcfa}")"
date="$(nearest_ansi "${dcol_3xa7:-78dce8}")"
tags="$(nearest_ansi "${dcol_2xa7:-ab9df2}")"
title="$(nearest_ansi "${dcol_4xa9:-ff6188}")"

BODY="$body" DATE="$date" TAGS="$tags" TITLE="$title" python3 <<'PYEOF'
import os
import yaml

path = os.path.expanduser("~/.config/jrnl/jrnl.yaml")
with open(path) as f:
    config = yaml.safe_load(f) or {}

config["colors"] = {
    "body": os.environ["BODY"],
    "date": os.environ["DATE"],
    "tags": os.environ["TAGS"],
    "title": os.environ["TITLE"],
}

with open(path, "w") as f:
    yaml.safe_dump(config, f, default_flow_style=False, sort_keys=False)
PYEOF
