#!/bin/bash
# Event-driven mpris status for polybar (tail = true) and eww's
# nowplaying popup (tail -F on the jsonl log below). One playerctl
# --follow stream, two consumers.

CLEAR_DELAY=300
JSON_LOG="$HOME/.cache/polybar/nowplaying.jsonl"
mkdir -p "$(dirname "$JSON_LOG")"
_clear_pid=""

emit_json() {
    # overwrite, not append — eww's deflisten only needs the latest line
    # (tail -F re-reads on truncation), and this keeps the file from
    # growing unbounded over a long uptime.
    python3 - "$1" "$2" "$3" "$4" "$5" "$6" <<'PYEOF' > "$JSON_LOG"
import json, sys
status, title, artist, album, art, length = sys.argv[1:7]
print(json.dumps({"status": status, "title": title, "artist": artist, "album": album, "art": art, "length": length}))
PYEOF
}

while IFS= read -r line; do
    status="${line%%|*}"
    title="${line#*|}"

    [ -n "$_clear_pid" ] && kill "$_clear_pid" 2>/dev/null
    _clear_pid=""

    artist=$(playerctl metadata artist 2>/dev/null)
    album=$(playerctl metadata album 2>/dev/null)
    art_url=$(playerctl metadata mpris:artUrl 2>/dev/null)
    length=$(playerctl metadata --format '{{duration(mpris:length)}}' 2>/dev/null)
    art_path=""
    [[ "$art_url" == file://* ]] && art_path="${art_url#file://}"
    emit_json "$status" "$title" "$artist" "$album" "$art_path" "$length"

    case "$status" in
        Playing)
            t="$title"
            [ "${#t}" -gt 40 ] && t="${t:0:40}…"
            echo "󰝚 $t"
            ;;
        Paused|Stopped)
            { sleep "$CLEAR_DELAY" && echo ""; } &
            _clear_pid=$!
            ;;
    esac
done < <(playerctl --follow metadata --format '{{status}}|{{title}}' 2>/dev/null)

echo ""
