#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src_root="$repo_root/dotfiles"

find "$src_root" -type f | while IFS= read -r src; do
    rel="${src#"$src_root"/}"
    dest="$HOME/$rel"
    mkdir -p "$(dirname "$dest")"

    # HyDE's own theme-file scanners (~/.local/lib/hyde/globalcontrol.sh's
    # find_wallpapers(), and color.set.sh's `find -H "$HYDE_THEME_DIR"
    # -type f -name "*.theme"` deployList scan) walk a theme directory with
    # `find -H ... -type f`. -H only dereferences a symlink that is find's
    # own starting-point argument — a symlink it *encounters while
    # recursing* still reports its own type (l), not the type of what it
    # points to. A symlinked wall.png is invisible to `-type f`, so HyDE
    # logs "No compatible wallpapers found" even though the file is a
    # perfectly valid image. The exact same blind spot hits *.theme/.sort:
    # if e.g. waybar.theme is a symlink, color.set.sh's deployList scan
    # can't see it, silently falls back to the *global* wallbash dcol
    # template for waybar, and renders wallpaper-extracted colors instead
    # of the theme's own literal palette — confirmed live with Monokai-Pro
    # (see docs/monokai-pro-palette.md). Every other dotfile stays a live
    # symlink (edits in this repo apply immediately, no re-run needed);
    # only files HyDE's own tree-walk needs to see directly — the
    # wallpaper and every top-level *.theme/.sort file in a theme dir —
    # have to be real files/copies.
    # color.set.sh's *own* template scan (`find -H "${wallbashDirs[@]}"
    # -type f -path "*/theme*" -name "*.dcol"`, plus the equivalent for
    # */always/*.dcol and */scripts/*) hits the identical blind spot for
    # anything under .config/hyde/wallbash/ — a symlinked custom *.dcol
    # template, or the script its post-command shells out to, is invisible
    # to that scan too.
    case "$rel" in
    .config/hyde/themes/*/wall.*|.config/hyde/themes/*/wallpapers/*|.config/hyde/themes/*/*.theme|.config/hyde/themes/*/.sort|.config/hyde/wallbash/*)
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
