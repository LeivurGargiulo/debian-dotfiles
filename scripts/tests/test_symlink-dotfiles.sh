#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/repo/scripts" "$tmp/repo/dotfiles/.config/hypr" \
    "$tmp/repo/dotfiles/.config/hyde/themes/Monokai-Pro"
echo "placeholder" > "$tmp/repo/dotfiles/.config/hypr/monitors.conf"
echo "fake wallpaper bytes" > "$tmp/repo/dotfiles/.config/hyde/themes/Monokai-Pro/wall.png"

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

# The theme wallpaper must be a real file, not a symlink: HyDE's own
# wallpaper scanner (~/.local/lib/hyde/globalcontrol.sh, find_wallpapers())
# walks the theme directory with `find -H ... -type f`, and -H only
# dereferences find's own starting-point argument — a symlink it encounters
# while *recursing* still reports as type l, not f, so a symlinked wall.png
# is invisible to it and HyDE reports "No compatible wallpapers found" even
# though the file is a perfectly valid image. Confirmed against a real run.
wall="$fake_home/.config/hyde/themes/Monokai-Pro/wall.png"
if [[ -L "$wall" ]]; then
    echo "FAIL: $wall is a symlink — HyDE's find -type f wallpaper scan won't see it" >&2
    exit 1
fi
if [[ ! -f "$wall" ]]; then
    echo "FAIL: $wall was not created" >&2
    exit 1
fi
if ! cmp -s "$wall" "$tmp/repo/dotfiles/.config/hyde/themes/Monokai-Pro/wall.png"; then
    echo "FAIL: $wall content does not match the source wallpaper" >&2
    exit 1
fi

# Re-run to confirm idempotency (no error, still a valid symlink / real file)
HOME="$fake_home" "$tmp/repo/scripts/symlink-dotfiles.sh"
[[ -L "$link" ]] || { echo "FAIL: not idempotent (regular dotfile)"; exit 1; }
[[ -f "$wall" && ! -L "$wall" ]] || { echo "FAIL: not idempotent (wallpaper)"; exit 1; }

# A source wallpaper update must actually propagate on re-run, not just get
# skipped because a file already exists at the destination.
echo "updated wallpaper bytes" > "$tmp/repo/dotfiles/.config/hyde/themes/Monokai-Pro/wall.png"
HOME="$fake_home" "$tmp/repo/scripts/symlink-dotfiles.sh"
if ! cmp -s "$wall" "$tmp/repo/dotfiles/.config/hyde/themes/Monokai-Pro/wall.png"; then
    echo "FAIL: wallpaper update did not propagate on re-run" >&2
    exit 1
fi

echo "PASS"
