#!/usr/bin/env bash
set -euo pipefail

# HyDE's wallbash engine sources every theme's *.dcol file as a plain bash
# script (confirmed live: applying this repo's Monokai-Pro theme threw
# "syntax error near unexpected token '('" on a real box). An rgba(...)
# value assigned without quotes — dcol_pry1_rgba=rgba(45,42,46,0.95) — is
# invalid bash: unquoted parens after '=' are parsed as a subshell, not part
# of the value. It must be quoted: dcol_pry1_rgba="rgba(45,42,46,0.95)",
# matching every stock HyDE theme's own .dcol files. Unlike theme.conf
# (Hyprland's own config syntax, never bash), .dcol really is bash — plain
# `bash -n` is the actual mechanism wallbash uses to load it, so this check
# uses the same interpreter, not a heuristic.

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
done < <(find "$repo_root/dotfiles" -iname "*.dcol" -print0)

if (( fail )); then
    exit 1
fi

echo "PASS"
