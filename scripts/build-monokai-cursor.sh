#!/usr/bin/env bash
set -euo pipefail

# Builds a Monokai Pro-colored Bibata cursor theme via cbmp (Bibata_Cursor's
# own color-build tool) + ctgen (clickgen's cursor-theme generator), and
# installs it to ~/.local/share/icons/Bibata-Monokai. Idempotent: skips the
# whole build if that directory already exists.
#
# Needs: yarn, python-clickgen (ctgen), and a Node/npm on PATH for `npx` —
# this repo installs Node via nvm in install.sh before this script runs.

theme_name="Bibata-Monokai"
dest_dir="$HOME/.local/share/icons/$theme_name"

if [[ -d "$dest_dir" ]]; then
    echo "==> $dest_dir already exists, skipping cursor build"
    exit 0
fi

if ! command -v yarn >/dev/null 2>&1; then
    echo "error: yarn not found (expected from packages/pacman.txt)" >&2
    exit 1
fi

if ! command -v ctgen >/dev/null 2>&1; then
    echo "error: ctgen not found (expected from packages/aur.txt's python-clickgen)" >&2
    exit 1
fi

tmp_cursor="$(mktemp -d)"
trap 'rm -rf "$tmp_cursor"' EXIT

git clone --depth 1 https://github.com/ful1e5/Bibata_Cursor "$tmp_cursor/Bibata_Cursor"
(
    cd "$tmp_cursor/Bibata_Cursor"
    yarn install
    npx cbmp -d 'svg/modern' -o 'bitmaps/Bibata-Monokai' \
        -bc '#ab9df2' -oc '#2d2a2e'
    ctgen build.toml -d 'bitmaps/Bibata-Monokai' \
        -n "$theme_name" -c 'Monokai Pro colored Bibata cursors.'
)

mkdir -p "$HOME/.local/share/icons"
cp -r "$tmp_cursor/Bibata_Cursor/themes/$theme_name" "$dest_dir"

echo "==> installed $theme_name to $dest_dir"
