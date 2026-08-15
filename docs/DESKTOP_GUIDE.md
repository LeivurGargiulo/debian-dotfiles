# Desktop guide

What actually runs on login, and what each rofi menu is for. For the
package/tool list see [SOFTWARE_LIST.md](SOFTWARE_LIST.md); for every
hotkey see [KEYBINDINGS.md](KEYBINDINGS.md); to change any of this see
[CUSTOMIZING.md](CUSTOMIZING.md).

## What starts on login

Defined in `chezmoi/dot_config/i3/config`'s `exec` block, in order:

1. `dex --autostart` — runs any `.desktop` autostart entries (GTK/Qt
   app trays register themselves here)
2. `dunst` — notification daemon
3. `polybar/launch.sh` — the top status bar
4. `nitrogen --restore` — reapplies last-set wallpaper
5. `picom` — compositor (animations/blur/shadows/translucency, see below)
6. `flameshot` — screenshot tool, sits in tray until invoked
7. `nm-applet`, `blueman-applet` — network/Bluetooth tray icons
8. `lxpolkit` — GUI auth prompt for privileged actions (mount, package
   installs from a GUI, etc.)
9. `greenclip daemon` — clipboard history collector
10. `kitty --class dropdown_term` — spawns the dropdown terminal once,
    then it's parked in the scratchpad (see below)

## picom (compositor)

Built from source (`pijulius/picom`, `implement-window-animations`
branch) rather than the Debian apt package, because that fork adds
window animations the stock build doesn't have. Config:
`chezmoi/dot_config/picom/i3.conf`.

- **Animations**: window open ("squeeze"), transient windows
  ("slide-down"), workspace switches ("auto" — picom infers a
  sensible transition)
- **Translucency**: 90% opacity for the active window, 75% inactive,
  85% specifically for kitty/Thunar; zen-beta and discord are pinned
  to 100% (video/browser content looks wrong translucent)
- **Blur**: dual_kawase, strength 5, applied to what shows through the
  translucent windows
- **Shadow**: soft drop shadow, radius 7, offset -7/-7
- Toggle the whole thing on/off at runtime with `mod+p` (kills/respawns
  the picom process — see `dot_local/share/i3/scripts/executable_toggle_picom.sh`)

## The five rofi menus

All rofi invocations share the Catppuccin Mocha theme
(`rofi/local/themes/catppuccin-mocha.rasi`) and the `i3.rasi` config
(icons on, drun shows `.desktop` `Comment=` text as a second line).

| Bind | Mode | What it shows |
|---|---|---|
| `mod+a` | `drun` (built-in) | every installed app with a `.desktop` file — name, icon, one-line description |
| `mod+shift+a` | `tui-menu` (script) | terminal-only tools with **no** `.desktop` entry: rtorrent, taskwarrior-tui, cmus, glow, rbw, wden, oathtool — each opens in a kitty window |
| `mod+Tab` | `window` (built-in) | every currently open window, across all workspaces, to jump to |
| `mod+c` | `clipboard` (greenclip) | last 50 clipboard entries, pick one to paste |
| `mod+o` | `audio-switch` (script) | every pactl sink, pick one to become the default output (moves currently-playing streams too) |
| `mod+slash` | `keybind-help` (script) | this repo's keybind list, statically written — not auto-generated from the config |
| `mod+ctrl+Delete` | `menu` (rofi-power-menu script) | logout / suspend / reboot / shutdown |

The four script-mode menus (`tui-menu`, `audio-switch`,
`keybind-help`, `rofi-power-menu`) live in
`chezmoi/dot_local/share/rofi/scripts/`. Rofi script mode: called with
no args it prints the menu lines; called with the chosen line as `$1`
it performs the action. See [CUSTOMIZING.md](CUSTOMIZING.md) to add
entries to any of them.

## Dropdown terminal

A kitty instance tagged `--class dropdown_term`, spawned once at
login, immediately floated + moved to the scratchpad by the
`for_window [instance="dropdown_term"]` rule in `i3/config`. `mod+grave`
toggles it show/hide — it's always running in the background, so
toggling is instant (no relaunch).

## Workspaces

10 workspaces, numbered 1-10 via `mod+1..0`. 1-4 carry fixed icons
(terminal, browser, files, code) as a visual hint for "this is where I
usually put X" — they don't auto-rename based on what's actually
running. 5-10 use a generic workspace glyph. See
[CUSTOMIZING.md](CUSTOMIZING.md#change-workspace-icons).

## Polybar modules

Left to right: `rofi` (click to open drun) → `xworkspaces` → `tray`
… (center: clock) … `pulseaudio` → `backlight` → `memory` → `cpu` →
`public-ip` (via `ip_monitor.sh`, refreshes every 5 min) → `wlan` →
`battery`×3 (percentage / wattage / time-remaining) → `powermenu`
(click to open the same rofi power menu as `mod+ctrl+Delete`).

## Lock screen

`mod+ctrl+l` runs `betterlockscreen -l dim` (script:
`dot_local/share/i3/scripts/executable_lock.sh`). Themed Catppuccin
Mocha Mauve via `chezmoi/dot_config/betterlockscreen/betterlockscreenrc`.
No auto-lock-on-idle is configured — see
[KEYBINDINGS.md](KEYBINDINGS.md#not-bound-deliberately).

## What's NOT part of this desktop layer

- No compositor picture-in-picture / window peek — picom here is
  purely visual (blur/shadow/animation), not a feature layer
- No workspace auto-naming by running app (would need an extra daemon
  like `i3-workspace-names-daemon` — skipped, static icons chosen
  instead, see the original brainstorm in git history)
- No per-app opacity beyond the 4 rules in `picom/i3.conf` — add more
  as needed, see [CUSTOMIZING.md](CUSTOMIZING.md#change-picom-opacityblur)
