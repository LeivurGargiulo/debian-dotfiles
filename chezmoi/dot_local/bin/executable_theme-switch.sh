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
command -v i3-msg >/dev/null 2>&1 && i3-msg reload >/dev/null

echo "theme -> $THEME"
