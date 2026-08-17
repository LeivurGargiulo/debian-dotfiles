#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src_root="$repo_root/dotfiles"

find "$src_root" -type f | while IFS= read -r src; do
    rel="${src#"$src_root"/}"
    dest="$HOME/$rel"
    mkdir -p "$(dirname "$dest")"

    # HyDE's own wallpaper scanner (~/.local/lib/hyde/globalcontrol.sh,
    # find_wallpapers()) walks a theme directory with `find -H ... -type f`.
    # -H only dereferences a symlink that is find's own starting-point
    # argument — a symlink it *encounters while recursing* still reports its
    # own type (l), not the type of what it points to, so a symlinked
    # wall.png is invisible to `-type f` and HyDE logs "No compatible
    # wallpapers found" even though the file is a perfectly valid image.
    # Confirmed live. Every other dotfile stays a live symlink (edits in
    # this repo apply immediately, no re-run needed); only the wallpaper
    # itself has to be a real file for HyDE's own tree-walk to see it.
    case "$rel" in
    .config/hyde/themes/*/wall.*)
        rm -f "$dest"
        cp "$src" "$dest"
        echo "copied: ~/$rel"
        ;;
    *)
        ln -sfn "$src" "$dest"
        echo "linked: ~/$rel"
        ;;
    esac
done
