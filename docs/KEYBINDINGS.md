# Keybindings

Everything bound in i3. Source of truth is always
`chezmoi/dot_config/i3/config` — this is a snapshot, regenerate by hand
if binds change. `$mod` is the Windows/Super key. There is no in-rofi
cheat-sheet anymore (the old `mod+slash` script menu was dropped when
i3/polybar/rofi were re-vendored from
[vari-sh/Catppuccin-i3-dotfiles](https://github.com/vari-sh/Catppuccin-i3-dotfiles)
— see git history "Re-vendor i3/polybar/rofi") — this doc is the only
cheat-sheet now.

## Apps / launchers

| Bind | Action |
|---|---|
| `mod+Return` | open terminal (kitty) |
| `mod+d` | app launcher (rofi drun, with icons) |
| `mod+Tab` / `mod+shift+Tab` | next / previous workspace |
| `mod+c` | clipboard history (greenclip via rofi) |
| `mod+shift+e` | power menu (rofi: lock/logout/reboot/shutdown) |
| `mod+x` | lock screen (betterlockscreen) |
| `mod+p` | toggle picom (compositor effects) on/off |

## Windows

| Bind | Action |
|---|---|
| `mod+shift+q` | kill focused window |
| `mod+j / k / l / semicolon` | focus left / down / up / right |
| `mod+Left/Down/Up/Right` | focus left/down/up/right (arrow-key alt) |
| `mod+shift+j / k / l / semicolon` | move window left / down / up / right |
| `mod+shift+Left/Down/Up/Right` | move window (arrow-key alt) |
| `mod+h` | split horizontal |
| `mod+v` | split vertical |
| `mod+s` | stacking layout |
| `mod+w` | tabbed layout |
| `mod+e` | toggle split layout |
| `mod+f` | fullscreen toggle |
| `mod+shift+space` | floating toggle |
| `mod+space` | toggle focus between tiling / floating |
| `mod+a` | focus parent container |
| `mod+r` | resize mode (then `j/k/l/;` or arrows, `Return`/`Escape`/`mod+r` to exit) |
| `mod+minus` | show/cycle scratchpad windows |
| `mod+shift+minus` | move focused window to scratchpad |

`j`=left, `k`=down, `l`=up, `semicolon`=right — a Colemak-ish remap so
the arrow keys stay free as a fallback. Arrow keys always work too.

## Workspaces

| Bind | Action |
|---|---|
| `mod+1..0` | switch to workspace 1-10 |
| `mod+shift+1..0` | move focused container to workspace 1-10 |

Workspaces are plain numbers (`1`.."10"`), no icons — the earlier
icon-labeled workspace set (`"1:terminal-icon"` etc.) was dropped in the
same re-vendor. See [CUSTOMIZING.md](CUSTOMIZING.md#change-workspace-names)
to add icons back if you want them.

## Screenshots (flameshot)

| Bind | Action |
|---|---|
| `mod+shift+s` | flameshot GUI (select region, annotate) |

## Media / hardware keys

| Bind | Action |
|---|---|
| `XF86AudioRaiseVolume` / `LowerVolume` | volume ±10% |
| `XF86AudioMute` | mute toggle |
| `XF86AudioMicMute` | mic mute toggle |
| `XF86MonBrightnessUp` / `Down` | screen brightness ±10% |

## Admin

| Bind | Action |
|---|---|
| `mod+shift+c` | reload i3 config |
| `mod+shift+r` | restart i3 in place |
| `mod+shift+x` | exit i3 (confirm dialog) |

## Not bound (deliberately)

- No dropdown/quake-style terminal — the earlier `mod+grave` scratchpad
  terminal was dropped in the i3/polybar/rofi re-vendor; `mod+Return`
  opens a normal kitty window instead.
- No dedicated browser/file-manager/wallpaper-manager binds — launch
  Zen Browser, Thunar, or nitrogen from `mod+d` (drun) instead. The old
  `mod+f`/`mod+e`/`mod+n` binds for these were reclaimed by i3 window
  commands (fullscreen / layout toggle / — respectively) to match
  upstream vari-sh's layout.
- No window-switcher, audio-device-switcher, or TUI-app-launcher rofi
  modes — those were custom scripts added in an earlier session and
  removed in the re-vendor along with their keybinds
  (`mod+Tab`-as-window-switcher, `mod+o`, `mod+shift+a`).
- No lock/screensaver timeout — `mod+x` is manual-only. Add an idle
  daemon (e.g. `xss-lock` + `betterlockscreen`) if you want auto-lock;
  not currently installed.
