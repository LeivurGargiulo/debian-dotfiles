#!/usr/bin/env bash
set -euo pipefail

# HyDE's wallbash engine sources a theme's palette-override file — the one
# literally named theme.dcol — as a plain bash script (confirmed live:
# applying this repo's Monokai-Pro theme threw "syntax error near
# unexpected token '('" on a real box, from color.set.sh's `source
# "$HYDE_THEME_DIR/theme.dcol"`). An rgba(...) value assigned without
# quotes — dcol_pry1_rgba=rgba(45,42,46,0.95) — is invalid bash: unquoted
# parens after '=' are parsed as a subshell, not part of the value. It must
# be quoted: dcol_pry1_rgba="rgba(45,42,46,0.95)".
#
# This does NOT apply to wallbash *template* .dcol files (e.g.
# dotfiles/.config/hyde/wallbash/theme/*.dcol) — those are sed-substituted
# by fn_wallbash's `sed '1d' "$template" | sed -i "$NORMAL_SED_SCRIPT"`,
# never sourced, so they're free to be JSON/YAML/CSS/XML/tmux-conf, exactly
# like HyDE's own stock kitty.dcol/waybar.dcol/rofi.dcol templates (none of
# which are valid bash either). Only the exact filename theme.dcol gets the
# bash-source treatment, so only that name is checked here.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
err_file="$(mktemp)"
trap 'rm -f "$err_file"' EXIT

fail=0
while IFS= read -r -d '' dcol; do
    if ! bash -n "$dcol" 2>"$err_file"; then
        echo "FAIL: $dcol is not valid bash (wallbash sources it as one):" >&2
        cat "$err_file" >&2
        fail=1
    fi
done < <(find "$repo_root/dotfiles" -iname "theme.dcol" -print0)

if (( fail )); then
    exit 1
fi

echo "PASS"
