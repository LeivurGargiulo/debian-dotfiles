# i3 ricing rebuild — design

## Context

Current desktop layer is KDE Plasma 6 + Catppuccin, orchestrated by
`ansible/roles/desktop` and `ansible/roles/theme`, applied on top of a
Debian base (see `2026-08-14-ansible-dotfiles-rebuild-design.md`). It has
been an ongoing source of breakage (upstream Catppuccin/Papirus/cursor
fetch scripts moving or dropping their install methods — see recent commit
history). Decision: drop Plasma entirely and replace it with an i3 setup
modeled on [vaelixd/i3-dotfiles](https://github.com/vaelixd/i3-dotfiles),
keeping the existing ansible + chezmoi orchestration pattern rather than
that repo's own manual-copy install method.

## Scope

Full "ricing" replacement: window manager, bar, launcher, compositor,
notifications, login manager, GTK/Qt app theming, cursor theme, icon
theme, fonts, terminal, editor, file manager (GUI + TUI), and
system-info tool. Everything ports through the existing ansible roles and
chezmoi source, not upstream's manual clone-and-copy approach.

## Decisions

- **Orchestration**: unchanged. `ansible/site.yml` role order stays
  `packages → desktop → theme → dotfiles → shell-env → dev-tools`.
  Bootstrap command stays `ansible-playbook site.yml --ask-become-pass`.
- **Window manager stack**: i3, Polybar, Rofi, Picom, Dunst (matches
  upstream).
- **Login manager**: swap SDDM → LightDM (+ webkit2 greeter). SDDM has no
  reason to stay once Plasma is gone; LightDM is the more common i3
  pairing.
- **Icon theme**: keep Papirus + Catppuccin folder colors (already
  working, recently fixed) — do not switch to upstream's Tela Circle
  Dracula.
- **Cursor theme**: keep existing Catppuccin Mocha Mauve cursor role
  as-is.
- **Font**: switch fully to CaskaydiaCove Nerd Font everywhere. Remove
  `fonts-jetbrains-mono` and all JetBrains references (including
  `kitty.conf`). No Debian apt package exists for CaskaydiaCove Nerd
  Font — install via GitHub release zip (nerd-fonts repo), same pattern
  as other manually-installed tools in `packages` role.
- **GTK/Qt app theming**: Catppuccin GTK theme (already scripted) +
  Kvantum, wired through `qt5ct` + `lxappearance` instead of Plasma's
  `kwriteconfig6`/kdeglobals integration.
- **System tray replacements** for dropped Plasma components:
  - `kde-spectacle` → Flameshot (screenshots)
  - `plasma-nm` → `network-manager-gnome` (nm-applet)
  - `bluedevil` → Blueman
  - polkit agent (mandatory outside Plasma/GNOME) → `policykit-1-gnome`
- **Terminal**: Kitty stays the sole terminal. Konsole and its
  Catppuccin profile/colorscheme tasks are removed entirely.
- **Editor / extras**: full port beyond the WM layer — Neovim, Yazi,
  Fastfetch (with a custom Catppuccin-themed logo/icon module, not the
  default distro ASCII art), Thunar, Zen Browser and Flameshot
  integration configs, all as shipped by i3-dotfiles, retextured to
  Papirus + CaskaydiaCove + Catppuccin Mocha Mauve instead of upstream's
  Tela Circle Dracula + CaskaydiaCove.
- **Wallpaper**: `plasma-apply-wallpaperimage` has no i3 equivalent;
  replaced with `feh --bg-fill` invoked from the i3 config's startup
  block, same Catppuccin Mocha wallpaper asset already fetched.

## Removed entirely

Plasma desktop packages, KWin (+ Polonium tiling script build steps),
SDDM (package, service, Catppuccin SDDM theme), Konsole (package,
Catppuccin colorscheme, profile), `kde-config-gtk-style`,
`kpackagetool6`, all `kwriteconfig6`/kdeglobals/`plasma-apply-*` command
tasks.

## Role-by-role changes

### `ansible/roles/desktop`

Replace Plasma package install + SDDM enable + graphical.target symlink +
Polonium build with:
- Install `i3_packages` (new group_vars list): i3-wm, polybar, rofi,
  picom, dunst, lightdm, lightdm-webkit2-greeter (or equivalent),
  network-manager-gnome, blueman, flameshot, policykit-1-gnome,
  lxappearance, qt5ct, thunar, thunar-archive-plugin, feh.
  (kitty, neovim, yazi, fastfetch already covered elsewhere in
  `apt_packages`/manual installs — verify and dedupe during
  implementation.)
- Enable `lightdm` service (replaces sddm enable).
- Keep the `default.target → graphical.target` symlink task as-is.

### `ansible/roles/theme`

Keep, retarget, or drop each existing task:
- Papirus + Catppuccin folder colors: **keep unchanged**.
- Catppuccin cursor theme fetch/install: **keep unchanged**.
- `theme_packages`: drop `fonts-jetbrains-mono`; font now installed via
  a new GitHub-release-style task (nerd-fonts CaskaydiaCove zip →
  `~/.local/share/fonts` → `fc-cache -f`).
- Plasma color scheme fetch/apply (`plasma-apply-colorscheme`): **drop**.
- Wallpaper fetch: **keep**; apply step becomes a `feh --bg-fill` call
  from i3 config startup instead of `plasma-apply-wallpaperimage`.
- catppuccin-kde Global Theme install: **drop**.
- Kvantum theme fetch: **keep**; widget-style activation switches from
  `kwriteconfig6 kdeglobals` to `qt5ct` config (`~/.config/qt5ct/qt5ct.conf`,
  set `style=kvantum`) plus `QT_QPA_PLATFORMTHEME=qt5ct` exported in the
  session (i3 config or `/etc/environment`).
- SDDM Catppuccin theme fetch/install: **drop**. (LightDM greeter theming
  is a nice-to-have; if no maintained Catppuccin LightDM webkit2 theme
  is found during implementation, ship LightDM with default styling and
  note it as a known gap — do not block on this.)
- Konsole colorscheme/profile tasks: **drop**.
- GTK theme fetch + GTK3/GTK4 settings.ini: **keep unchanged**.

### `ansible/group_vars/all/packages.yml`

- Remove `plasma_packages`, add `i3_packages` (see above).
- `theme_packages`: remove `fonts-jetbrains-mono`.
- Add Neovim, Yazi, Fastfetch to `apt_packages` if not already present
  (verify during implementation — Yazi is currently a manual GitHub
  release binary, keep as-is).

### `chezmoi/dot_config/`

New directories, ported from i3-dotfiles and retextured (Papirus icons,
CaskaydiaCove Nerd Font, Catppuccin Mocha Mauve colors — not upstream's
Tela/Dracula):
- `i3/config`
- `polybar/` (config + launch script)
- `rofi/`
- `picom.conf`
- `dunst/dunstrc`
- `nvim/` (full config port)
- `yazi/`
- `fastfetch/config.jsonc` (custom Catppuccin logo/icon module)
- Thunar, Zen Browser, Flameshot config files as shipped upstream

`kitty.conf`: update `font_family` from `JetBrainsMono Nerd Font` to
`CaskaydiaCove Nerd Font`.

## Testing / verification

This is a live-machine desktop-environment swap — no unit tests apply.
Verification plan (detailed further in the implementation plan):
1. `ansible-playbook site.yml --check` where tasks support check mode,
   to catch obvious syntax/task errors before a real run.
2. Apply on the actual machine (or a VM/snapshot if available) and
   confirm: LightDM presents a session, i3 starts, Polybar/Rofi/Dunst/
   Picom are running, GTK/Qt apps pick up Catppuccin theming, kitty and
   fastfetch show the new font/logo, Neovim config loads without error.
3. Explicit user checkpoint before calling the branch done — reboot and
   confirm the session works, per `verification-before-completion`.

## Known gaps / follow-ups

- LightDM Catppuccin greeter theme may not exist upstream; default
  LightDM styling is an acceptable fallback, not a blocker.
- CaskaydiaCove Nerd Font has no Debian apt package; installed via
  manual GitHub release fetch, same pattern as other manual tools.
