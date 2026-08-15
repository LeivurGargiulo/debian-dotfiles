# Keybindings

Everything bound in i3. Source of truth is always
`chezmoi/dot_config/i3/config` — this is a snapshot, regenerate by hand
if binds change. `$mod` is the Windows/Super key. `mod+slash` opens a
live rofi version of this list on the running machine.

## Apps / launchers

| Bind | Action |
|---|---|
| `mod+Return` | open terminal (kitty) |
| `mod+f` | open browser (zen-browser) |
| `mod+e` | open file manager (Thunar) |
| `mod+a` | app launcher (rofi drun) |
| `mod+shift+a` | curated TUI app launcher (see [DESKTOP_GUIDE.md](DESKTOP_GUIDE.md)) |
| `mod+Tab` | window switcher — jump to any open window |
| `mod+grave` | toggle dropdown terminal (quake-style, scratchpad) |
| `mod+n` | wallpaper manager (nitrogen) |
| `mod+c` | clipboard history (greenclip via rofi) |
| `mod+o` | audio output/input device switcher |
| `mod+slash` | keybind cheat-sheet (this list, in rofi) |
| `mod+ctrl+l` | lock screen (betterlockscreen) |
| `mod+p` | toggle picom (compositor effects) on/off |

## Windows

| Bind | Action |
|---|---|
| `mod+q` | kill focused window |
| `mod+j / k / l / semicolon` | focus left / down / up / right |
| `mod+Left/Down/Up/Right` | focus left/down/up/right (arrow-key alt) |
| `mod+shift+j / k / l / semicolon` | move window left / down / up / right |
| `mod+shift+Left/Down/Up/Right` | move window (arrow-key alt) |
| `mod+h` | split horizontal |
| `mod+v` | split vertical |
| `mod+g` | toggle split layout |
| `mod+s` | stacking layout |
| `mod+t` | tabbed layout |
| `mod+z` | fullscreen toggle |
| `mod+w` | floating toggle |
| `mod+r` | resize mode (then `j/k/l/;` or arrows, `Return`/`Escape`/`mod+r` to exit) |
| `mod+minus` | show/cycle scratchpad windows |
| `mod+shift+minus` | move focused window to scratchpad |

Custom focus/move letters (`j`=left, `k`=down, `l`=up, `semicolon`=right)
are a Colemak-ish remap set in `i3/config` via `$left`/`$down`/`$up`/`$right`
— arrow keys always work as a fallback, see [CUSTOMIZING.md](CUSTOMIZING.md#remap-focusmove-keys) to change them.

## Workspaces

| Bind | Action |
|---|---|
| `mod+1..0` | switch to workspace 1-10 |
| `mod+alt+1..0` | move focused container to workspace 1-10 |
| `mod+ctrl+Left/Right` | previous/next workspace |

Workspaces 1-4 carry fixed icons (terminal/browser/files/code); 5-10 use
a generic workspace glyph. See [CUSTOMIZING.md](CUSTOMIZING.md#change-workspace-icons)
to change them.

## Screenshots (flameshot)

| Bind | Action |
|---|---|
| `Print` | flameshot GUI (select region, annotate) |
| `mod+comma` | screenshot → clipboard |
| `mod+ctrl+comma` | screenshot → save dialog |
| `mod+alt+comma` | screenshot after 3s delay → clipboard |
| `mod+shift+comma` | screenshot after 3s delay → save dialog |

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
| `mod+ctrl+Delete` | logout menu (rofi: logout/suspend/reboot/shutdown) |

## Not bound (deliberately)

- No dedicated Discord launch bind — was `mod+d`, removed (see git
  history "Overhaul i3 hotkeys"), launch it from `mod+a` (drun) instead.
- No lock/screensaver timeout — `mod+ctrl+l` is manual-only. Add an idle
  daemon (e.g. `xss-lock` + `betterlockscreen`) if you want auto-lock;
  not currently installed.
