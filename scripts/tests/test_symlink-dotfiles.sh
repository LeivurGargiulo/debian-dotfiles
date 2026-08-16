#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/repo/scripts" "$tmp/repo/dotfiles/.config/hypr"
echo "placeholder" > "$tmp/repo/dotfiles/.config/hypr/monitors.conf"

script_under_test="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/symlink-dotfiles.sh"
cp "$script_under_test" "$tmp/repo/scripts/symlink-dotfiles.sh"
chmod +x "$tmp/repo/scripts/symlink-dotfiles.sh"

fake_home="$tmp/home"
mkdir -p "$fake_home"
HOME="$fake_home" "$tmp/repo/scripts/symlink-dotfiles.sh"

link="$fake_home/.config/hypr/monitors.conf"
if [[ ! -L "$link" ]]; then
    echo "FAIL: $link is not a symlink" >&2
    exit 1
fi
target="$(readlink -f "$link")"
expected="$tmp/repo/dotfiles/.config/hypr/monitors.conf"
if [[ "$target" != "$(readlink -f "$expected")" ]]; then
    echo "FAIL: symlink target = $target, expected $expected" >&2
    exit 1
fi

# Re-run to confirm idempotency (no error, still a valid symlink)
HOME="$fake_home" "$tmp/repo/scripts/symlink-dotfiles.sh"
[[ -L "$link" ]] || { echo "FAIL: not idempotent"; exit 1; }

echo "PASS"
