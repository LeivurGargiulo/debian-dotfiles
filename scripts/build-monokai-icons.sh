#!/usr/bin/env bash
set -euo pipefail

# Recolors Papirus's stock "violet" folder SVGs to exact Monokai Pro purple,
# registers them as a new "monokai" papirus-folders color name, then applies
# it. Same technique catppuccin/papirus-folders uses: vendor new folder SVGs
# under a new color name rather than passing a hex flag — papirus-folders
# only discovers colors from folder-<color>-documents.svg files already on
# disk in 48x48/places/ (verified against its real source at
# github.com/PapirusDevelopmentTeam/papirus-folders), and applies a color by
# symlinking matching folder-<color>*.svg / user-<color>*.svg files across
# FIVE size directories (22x22, 24x24, 32x32, 48x48, 64x64) — recoloring
# only one size directory would leave the other icon sizes un-recolored.
# Idempotent: skips generation if "monokai" SVGs already exist in all five
# size dirs, but always re-runs `papirus-folders -C monokai` (cheap, safe).

papirus_dir="/usr/share/icons/Papirus"
accent_hex="ab9df2"   # Monokai Pro purple, no leading '#' to match Papirus SVG fill syntax
sizes=(22x22 24x24 32x32 48x48 64x64)

if ! command -v papirus-folders >/dev/null 2>&1; then
    echo "error: papirus-folders not found (expected from packages/aur.txt)" >&2
    exit 1
fi

if [[ ! -d "$papirus_dir/48x48/places" ]]; then
    echo "error: $papirus_dir/48x48/places not found (expected from packages/pacman.txt's papirus-icon-theme)" >&2
    exit 1
fi

needs_generation=false
for size in "${sizes[@]}"; do
    if ! ls "$papirus_dir/$size/places/"folder-monokai*.svg >/dev/null 2>&1; then
        needs_generation=true
        break
    fi
done

if [[ "$needs_generation" == "true" ]]; then
    echo "==> generating Monokai Pro folder SVGs across ${sizes[*]}"
    for size in "${sizes[@]}"; do
        places_dir="$papirus_dir/$size/places"
        [[ -d "$places_dir" ]] || continue
        for src in "$places_dir/"folder-violet*.svg "$places_dir/"user-violet*.svg; do
            [[ -e "$src" ]] || continue
            dest="${src/-violet/-monokai}"
            sudo sed -E "s/#[0-9a-fA-F]{6}/#${accent_hex}/g" "$src" | sudo tee "$dest" >/dev/null
        done
    done
fi

papirus-folders -C monokai --theme Papirus

echo "==> Papirus folders recolored to Monokai Pro"
