# Desktop guide

What actually runs on login, and what each rofi menu is for. For the
package/tool list see [SOFTWARE_LIST.md](SOFTWARE_LIST.md); for every
hotkey see [KEYBINDINGS.md](KEYBINDINGS.md); to change any of this see
[CUSTOMIZING.md](CUSTOMIZING.md).

i3/polybar/rofi/picom/dunst are modeled on
[vari-sh/Catppuccin-i3-dotfiles](https://github.com/vari-sh/Catppuccin-i3-dotfiles),
retextured to this repo's existing Papirus icon theme, CaskaydiaCove
Nerd Font, and Debian base instead of upstream's own choices.

## What starts on login

Defined in `chezmoi/dot_config/i3/config`'s `exec` block, in order:

1. `xrandr --auto` — apply detected monitor geometry
2. `picom --config ~/.config/picom/i3.conf -b` — compositor (animations/
   blur/shadows/translucency, see below)
3. `setxkbmap -layout us,gb -option grp:alt_shift_toggle` — US/GB
   keyboard layouts, `alt+shift` to toggle
4. `nitrogen --restore` — reapplies last-set wallpaper
5. `polybar/launch.sh` — the top status bar
6. `nm-applet`, `blueman-applet`, `lxpolkit` — network/Bluetooth tray
   icons and the GUI polkit auth agent (upstream vari-sh never execs
   these, so polybar's tray module would otherwise sit empty — added
   deliberately, see git history "Re-vendor i3/polybar/rofi")
7. `dunst` — notification daemon
8. `greenclip daemon` — clipboard history collector
9. `dbus-update-activation-environment --all`
10. `dex --autostart` — runs any `.desktop` autostart entries
11. `xset s off` / `-dpms` / `s noblank` — disable screen blanking/DPMS

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
  the picom process — see
  `dot_local/share/i3/scripts/executable_toggle_picom.sh`)

## Rofi

Single theme file (`chezmoi/dot_config/rofi/config.rasi`, Catppuccin
Mocha Mauve, Papirus-Dark icons) shared by every rofi invocation. Two
entry points:

| Bind | Mode | What it shows |
|---|---|---|
| `mod+d` | `drun` (built-in) | every installed app with a `.desktop` file — icon + name |
| `mod+c` | `clipboard` (greenclip) | clipboard history, pick one to paste |
| `mod+shift+e` | power menu (`~/.local/share/rofi/scripts/powermenu.sh`) | Lock / Logout / Reboot / Shutdown |

The power menu is a plain bash script (not a rofi "modi" plugin) —
`rofi -dmenu` presents four options, the script `case`s on the choice.
Lock runs `~/.local/share/i3/scripts/lock.sh` (betterlockscreen);
Logout runs `i3-msg exit`; Reboot/Shutdown call `systemctl`.

## Polybar

One bar (`[bar/main]` in `chezmoi/dot_config/polybar/config.ini`),
launched by `~/.config/polybar/launch.sh` (`polybar main &`).

- **Left**: `rofi` (click → drun) → `i3` (workspaces) → `xwindow`
  (focused window title)
- **Center**: `date` (clock)
- **Right**: `pulseaudio` → `memory` → `cpu` → `public-ip` (via
  `scripts/ip_monitor.sh`, polls every 5 min, click-left copies the IP,
  click-right shows ISP/country/city) → `tray` (nm-applet/blueman
  icons land here) → `battery` → `powermenu` (click → same power menu
  as `mod+shift+e`)

`point` modules are just a small separator glyph between the modules
above — not a real data source.

## Lock screen

`mod+x` (or the power menu's Lock option) runs
`~/.local/share/i3/scripts/lock.sh`, which calls `betterlockscreen -l
dim`. Themed Catppuccin Mocha Mauve via
`chezmoi/dot_config/betterlockscreen/betterlockscreenrc`. No
auto-lock-on-idle is configured — see
[KEYBINDINGS.md](KEYBINDINGS.md#not-bound-deliberately).

## Terminal (kitty) and system info (fastfetch)

Kitty is fully Catppuccin Mocha themed (`chezmoi/dot_config/kitty/kitty.conf`)
against the [official catppuccin/kitty](https://github.com/catppuccin/kitty)
palette — base 16 colors plus cursor/scrollbar/URL/window-border/
titlebar/tab-bar/mark colors.

`fastfetch` (`chezmoi/dot_config/fastfetch/config.jsonc`) shows a real
Catppuccin logo PNG rendered through kitty's image protocol (works
because the terminal actually is kitty — no ASCII-art fallback needed),
laid out as boxed Hardware/Software sections with a nerd-font icon per
row (ported from
[Nukecraft5419/fastfetch](https://github.com/Nukecraft5419/fastfetch)).

## What's NOT part of this desktop layer

- No compositor picture-in-picture / window peek — picom here is
  purely visual (blur/shadow/animation), not a feature layer
- No workspace auto-naming by running app, no workspace icons (plain
  numbers only — see [KEYBINDINGS.md](KEYBINDINGS.md#workspaces))
- No per-app opacity beyond the 4 rules in `picom/i3.conf` — add more
  as needed, see [CUSTOMIZING.md](CUSTOMIZING.md#change-picom-opacityblur)
- No dropdown terminal, window switcher, audio-device switcher, or
  curated TUI-app launcher — these were custom rofi scripts from an
  earlier session, removed when i3/polybar/rofi were re-vendored from
  upstream vari-sh (see [KEYBINDINGS.md](KEYBINDINGS.md#not-bound-deliberately))
