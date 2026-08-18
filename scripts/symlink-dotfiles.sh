#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src_root="$repo_root/dotfiles"

# Records every destination this script has ever written via `cp` (as
# opposed to `ln -sfn`), so a later run can tell "this copy is stale because
# its dotfiles/ source was deleted" apart from "this file was never ours to
# begin with". That distinction matters a lot here: the copy-case
# directories (.config/hyde/themes/*/, .config/hyde/wallbash/) are shared
# with plenty of content this repo has no opinion on -- other HyDE themes,
# HyDE's own stock wallbash/always+scripts+theme templates. A first attempt
# at orphan cleanup scanned those directories wholesale and deleted all of
# that alongside the one real stale file it was after -- restored from
# vendor/hyde and each theme's themepatcher cache, but the lesson stuck:
# only ever remove a path this exact manifest previously wrote, never infer
# "orphan" from directory contents.
manifest="$repo_root/.git/symlink-dotfiles.copied-manifest"
declare -A copied_dests=()

while IFS= read -r src; do
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
    # of the theme's own literal palette — confirmed live. Every other dotfile stays a live
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
        copied_dests["$dest"]=1
        echo "copied: ~/$rel"
        ;;
    *)
        ln -sfn "$src" "$dest"
        echo "linked: ~/$rel"
        ;;
    esac
done < <(find "$src_root" -type f)

# Orphan cleanup: remove only destinations a *previous* run of this exact
# script copied and this run did not -- i.e. their dotfiles/ source was
# deleted. Never touch a path this manifest has no record of.
if [[ -f "$manifest" ]]; then
    while IFS= read -r old_dest; do
        [[ -n "$old_dest" && -z "${copied_dests["$old_dest"]:-}" && -e "$old_dest" ]] && {
            rm -f "$old_dest"
            echo "removed orphan: ${old_dest/#"$HOME"/\~}"
        }
    done <"$manifest"
fi
mkdir -p "$(dirname "$manifest")"
printf '%s\n' "${!copied_dests[@]}" >"$manifest"
