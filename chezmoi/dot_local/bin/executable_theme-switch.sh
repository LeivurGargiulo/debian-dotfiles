#!/usr/bin/env bash
# Instant theme switch between already-installed themes (orange|catppuccin).
# No sudo, no package installs, no network - just swaps already-vendored
# dotfiles into place and kicks the running session. For first-time setup
# (installing packages/fonts/cursors/GTK themes) use `theme-full` instead.
set -euo pipefail

THEME="${1:?usage: theme-switch.sh orange|catppuccin}"
SRC="$HOME/debian/ansible/roles/theme/files/$THEME"
[ -d "$SRC" ] || { echo "unknown theme: $THEME (expected orange|catppuccin)" >&2; exit 1; }

cp -rT "$SRC" "$HOME"

case "$THEME" in
  orange)
    WALLPAPER="$HOME/.local/share/wallpapers/orange-neon-glass.png"
    CURSOR_THEME="Bibata-Modern-Amber"
    BGCOLOR="#0D0704"
    ;;
  catppuccin)
    WALLPAPER="/usr/share/wallpapers/catppuccin-mocha.png"
    CURSOR_THEME="catppuccin-mocha-mauve-cursors"
    BGCOLOR="#1E1E2E"
    ;;
esac

mkdir -p "$HOME/.config/nitrogen"
cat > "$HOME/.config/nitrogen/bg-saved.cfg" <<EOF
[xin_-1]
file=$WALLPAPER
mode=5
bgcolor=$BGCOLOR
EOF

command -v gsettings >/dev/null 2>&1 && gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true

# GTK apps read cursor-theme via gsettings above, but the X root window
# (i.e. the cursor shown over tiles/gaps) resolves through
# ~/.icons/default - neither theme's vendored tree ships this file, so
# it never updated and stayed stuck on whichever theme set it last.
mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$CURSOR_THEME
EOF

# There's no xsettings daemon in this bare-i3 setup broadcasting the
# cursor theme, and XCURSOR_THEME is never exported anywhere, so
# already-running (and even newly spawned) non-GTK apps won't notice a
# gsettings or ~/.icons/default change alone. xrdb's Xcursor.theme
# resource is what raw libXcursor apps actually re-query live.
if command -v xrdb >/dev/null 2>&1; then
  printf 'Xcursor.theme: %s\nXcursor.size: 24\n' "$CURSOR_THEME" | xrdb -merge -
fi
command -v xsetroot >/dev/null 2>&1 && xsetroot -cursor_name left_ptr

command -v betterlockscreen >/dev/null 2>&1 && betterlockscreen -u "$WALLPAPER" >/dev/null 2>&1 &

# don't rely on i3 exec_always/exec firing reliably on reload - drive
# every themed daemon's restart directly instead. dunst and picom are
# `exec` (once-only) in i3's config, and dunst has no config-reload
# command in this version, so both need an explicit kill+respawn or
# they keep rendering the previous theme's colors indefinitely.
command -v nitrogen >/dev/null 2>&1 && nitrogen --restore &
if [ -x "$HOME/.config/polybar/launch.sh" ]; then
  "$HOME/.config/polybar/launch.sh" &
fi
if command -v dunst >/dev/null 2>&1; then
  pkill -x dunst 2>/dev/null || true
  nohup dunst >/dev/null 2>&1 &
  disown
fi
if command -v picom >/dev/null 2>&1; then
  pkill -x picom 2>/dev/null || true
  nohup picom --config "$HOME/.config/picom/i3.conf" -b >/dev/null 2>&1 &
  disown
fi
if command -v i3-msg >/dev/null 2>&1; then
  i3-msg reload >/dev/null
  # i3 doesn't retroactively rename already-created workspaces on
  # reload - a workspace's live name is set once, at creation time.
  # Config-only edits (like dropping workspace label icons) never
  # reach a workspace that already exists, so normalize any workspace
  # still carrying an icon suffix back to its plain number.
  i3-msg -t get_workspaces 2>/dev/null | python3 -c '
import json, sys, subprocess, re
for w in json.load(sys.stdin):
    name = w["name"]
    m = re.match(r"^(\d+):", name)
    if m and m.group(1) != name:
        subprocess.run(["i3-msg", "rename", "workspace", name, "to", m.group(1)])
' 2>/dev/null || true
fi

echo "theme -> $THEME"
