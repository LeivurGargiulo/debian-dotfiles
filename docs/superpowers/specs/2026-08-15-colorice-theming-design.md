# Colorice wallpaper-driven theming

Date: 2026-08-15

## Problem

Theming today is two static, hand-maintained trees (`catppuccin`, `orange`)
under `ansible/roles/theme/files/`, wholesale-copied to `~/` based on the
`dotfiles_theme` var. `orange` is mostly dead weight: a full GNOME/Cinnamon
GTK theme, Kvantum theme, qt5ct color scheme, and cursor set, all leftover
from a pre-i3 Plasma/GTK setup. Changing the look means hand-editing ~24
per-app config files across two trees.

Goal: replace this with [colorice](https://github.com/rattle99/colorice)
(rattle99), a pywal-style wallpaper-to-theme generator using Oklab color
extraction and WCAG contrast enforcement. Pick a wallpaper, run one command,
every themed app re-colors to match — no more hand-maintained duplicate
color trees.

## Scope

**In scope:**
- New `ansible/roles/colorice/` role: installs colorice, deploys its config
  and our custom templates.
- Wallpaper-reactive theming for all 24 currently-themed apps: kitty, i3,
  picom, polybar, neovim, dunst, rofi, cava, zellij (colorice-native
  templates) + fastfetch, aerc, atuin, bat, betterlockscreen, btop, delta,
  eza, fzf, lazygit, mpv, ncspot, starship, tmux, yazi (custom templates we
  write).
- Deleting the `orange` theme tree and its GTK/Kvantum/qt5ct/cursor assets.
- Retiring the `dotfiles_theme` enum; `catppuccin` becomes the single static
  base tree (layout, keybinds, non-color settings, and its own baked-in
  colors as the no-colorice-yet/fallback look).
- A one-keybind rice-refresh script bound in i3, matching colorice's
  documented pattern (random wallpaper → `colorice --apply`).

**Out of scope:**
- The `chezmoi/` mirror of these dotfiles. It tracks the live machine
  separately from ansible's provisioning tree; bringing it in sync is a
  follow-up chore, not part of this design.
- Cinnamon/GNOME/Kvantum/qt5ct theming — deleted, not replaced. This box
  runs bare i3; there is no consumer for those assets anymore.
- Automatic wallpaper rotation, multi-monitor palette logic, light-mode
  toggling — none of that exists today and isn't being added.

## Architecture

Two ansible roles, cleanly separated:

- **`theme`** (existing, trimmed): installs fonts (CaskaydiaCove Nerd Font),
  copies the `catppuccin` tree to `~/` unconditionally. No more
  `dotfiles_theme` branching, no more `orange`-only tasks (Kvantum dir,
  qt5ct dir, GTK theme fetch/unarchive, cursor-theme-per-branch — all of it
  goes, since those tasks were `orange`-only or theme-conditional).
- **`colorice`** (new): pipx-installs colorice, runs `colorice --init` to
  drop the 22 bundled templates, then overlays our `config.toml` (enabling
  exactly the 24 apps below, each mapped to its output path + reload hook)
  and our 15 custom template files into `~/.config/colorice/templates/`.

Ordering: `theme` runs first (lays down base configs with their static
catppuccin colors and, where needed, the new `include`/`source` line),
then `colorice` runs (installs the tool and templates). Actually applying
a wallpaper stays a runtime, user-triggered action — ansible never runs
`colorice --apply`. A freshly-provisioned box looks like static Catppuccin
Mocha until the user runs colorice once.

## Per-app wiring

Two mechanisms, matching colorice's own convention:

- **Include** — the app already loads external files (`include`, `source`,
  `import`, a themeable directive). The `theme` role's catppuccin base file
  gets one added line pointing at colorice's rendered output path. Colors
  come from that included file; the base file keeps layout/settings.
- **Rewrite** — the app has no clean include mechanism for colors. Colorice
  fully owns and overwrites that config file on apply, same as its own
  bundled `dunst.conf`/`cava.conf` templates. The `theme` role's copy of
  that file becomes the pre-colorice fallback content.

| App | Template | Mechanism | Notes |
|---|---|---|---|
| kitty | native (`kitty.conf`) | include | `include current-theme.conf`; hook `killall -USR1 kitty` |
| i3 | native (`i3-colors.conf`) | include | `include ~/.config/i3/colorice-colors.conf`; hook `i3-msg reload` |
| picom | native (`picom.conf`) | rewrite | colorice owns whole file, matches its bundled pattern |
| polybar | native (`polybar-colors.ini`) | include | `include-file =`; hook `polybar-msg cmd restart` |
| neovim | native (`neovim-colors.lua`) | include | `require("colorice-colors")` from custom/plugins/init.lua |
| dunst | native (`dunst.conf`) | rewrite | matches colorice's bundled pattern |
| rofi | native (`rofi-colors.rasi`) | include | `@import` in config.rasi |
| cava | native (`cava.conf`) | rewrite | matches colorice's bundled pattern |
| zellij | native (`zellij-theme.kdl`) | include | `theme` key in config.kdl points at rendered file |
| fastfetch | custom | rewrite | config.jsonc has colors inline throughout; no clean include point |
| aerc | custom | include | styleset already a separate file; point `styleset-name` at colorice output. Not currently wired in the ansible tree (only chezmoi has aerc.conf) — add it there too |
| atuin | custom | rewrite | `[theme]` table, small enough to fully own |
| bat | custom | rewrite | theme is a full `.tmTheme` file already; colorice renders it directly |
| betterlockscreen | custom | include | `betterlockscreenrc` is a sourced shell config; split color keys into a colorice-owned file, `source` it from the base rc |
| btop | custom | rewrite | `.theme` file, colorice renders it directly like bat |
| delta | custom | include | `[include] path = ~/.config/delta/colorice-colors.gitconfig` added to `.gitconfig` |
| eza | custom | rewrite | `theme.yml`, colorice renders directly |
| fzf | custom | rewrite | `.zshrc` already sources `~/.config/fzf/colors.zsh` unconditionally — colorice just needs to render that exact path, no base-file edit needed |
| lazygit | custom | rewrite | `gui.theme` block, colorice owns `config.yml` |
| mpv | custom | rewrite | small color-relevant subset of `mpv.conf`; colorice owns the file |
| ncspot | custom | rewrite | `[theme]` table, colorice owns `config.toml` |
| starship | custom | rewrite | colorice owns `starship.toml` |
| tmux | custom | include | `source-file ~/.config/tmux/colorice-colors.conf` added to tmux.conf |
| yazi | custom | include | yazi.toml `flavor` — colorice writes a `colorice` flavor dir, base config points at it |

## Data flow

```
wallpaper image
  → colorice <path> --apply
    → extract palette (Oklab KMeans, WCAG contrast)
    → render all 24 configured templates
    → run each template's reload hook
```

Re-running `colorice --apply` (no image arg) re-renders from the cached
palette — used by the rice-refresh keybind after picking a new random
wallpaper.

## Rice-refresh keybind

New script, `~/.local/bin/rice-refresh` (deployed by the `colorice` role),
following colorice's documented pattern, using nitrogen (already the
wallpaper tool here) instead of feh:

```bash
#!/usr/bin/env bash
WALLPAPER=$(find ~/Pictures/Wallpapers -type f | shuf -n 1)
nitrogen --set-zoom-fill "$WALLPAPER"
colorice "$WALLPAPER" --apply --no-preview -q
notify-send "Theme refreshed" "$(basename "$WALLPAPER")"
```

Bound to `$mod+shift+w` in the i3 config (`$mod+w` is already `layout
tabbed`; `$mod+shift+w` is free).

## Testing

- `ansible-playbook --syntax-check` and a `--check` dry run against a
  disposable VM/container for both roles.
- Provision fresh, confirm: colorice installed (`colorice --version`),
  `~/.config/colorice/templates/` has all 22 bundled + 15 custom templates,
  `~/.config/colorice/config.toml` has all 24 entries uncommented with
  correct output paths.
- Run `colorice ~/Pictures/Wallpapers/<any>.jpg --apply --no-preview -q`
  manually, confirm each app picks up new colors (spot-check kitty, i3,
  polybar reload; picom/dunst/cava/starship/lazygit/etc. file rewrite).
- Confirm `orange` theme is fully gone from the repo and `dotfiles_theme`
  var no longer referenced anywhere in ansible.
- Confirm a fresh provision with colorice never run still looks like intact
  static Catppuccin Mocha (fallback path).
