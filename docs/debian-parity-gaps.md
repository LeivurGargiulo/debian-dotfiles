# debian-dotfiles software not in arch-dotfiles

Everything in `debian-dotfiles/docs/SOFTWARE_LIST.md` that has no path into
`packages/pacman.txt` / `packages/aur.txt` here, grouped by why. Most of
the list *was* portable and already got ported (see `packages/` +
`README.md`'s "Not automated yet" section for the small residual). This
file is the rest: things that don't map cleanly.

## 1. Superseded by Hyprland/HyDE (X11-only, no port needed)

debian-dotfiles targets i3 (X11). HyDE already provides the Wayland/Hyprland
equivalent of each of these, so none were ported — installing them
alongside HyDE would just be redundant with what it already sets up:

xserver-xorg, xinit, i3-wm, i3lock, polybar, lightdm + lightdm-gtk-greeter,
network-manager-gnome, blueman, flameshot, lxpolkit, lxappearance, qt5ct,
thunar + thunar-archive-plugin, nitrogen, dex, light, pulseaudio-utils,
dunst, picom (the `implement-window-animations` fork, built from source in
debian — Hyprland has its own compositor), greenclip (clipboard daemon —
HyDE/Hyprland ships its own), betterlockscreen (screen lock — HyDE ships
`hyprlock` or equivalent).

`rofi` is the one exception worth naming: debian uses it as the i3 app
launcher/power menu, and HyDE typically ships it too (or `wofi`) as part
of its own Hyprland config — so it's already covered, just not via
`packages/pacman.txt` directly.

**Not a gap to fix** — re-verify what HyDE actually installs once
`install.sh` runs on real hardware; only add something here if HyDE
*doesn't* cover it.

## 2. Theming/config layer — mostly done (2026-08-16 ricing pass), residual gaps below

The ricing pass themed HyDE's own chrome (via `dotfiles/.config/hyde/themes/Monokai-Pro/`,
HyDE's wallbash engine) plus 21 CLI/TUI tools Monokai-Pro-style: bat, eza,
git-delta, fzf, tmux, zsh-syntax-highlighting, btop, cava, mangohud, yazi,
gitui, lazygit, zathura, mpv/uosc, newsboat, aerc, atuin, ncspot, cmus,
calcurse, taskwarrior. See `docs/monokai-pro-palette.md` for the canonical
palette and `docs/superpowers/plans/2026-08-16-monokai-pro-ricing.md` for
what was built.

**Deliberate deviation from debian, not a gap:** the zsh prompt is
Powerlevel10k (`dotfiles/.p10k.zsh`, AUR `zsh-theme-powerlevel10k`), not
debian's starship — user's explicit choice. Built from
romkatv/powerlevel10k's real official "classic" style template
(`config/p10k-classic.zsh`, fetched verbatim), with only the identity-color
vars overridden to the same 256-color nearest-index mapping used for
cmus/taskwarrior/newsboat elsewhere in this repo — not a from-scratch
fabrication of the ~1700-line generated config. `packages/pacman.txt`'s
`starship` and `dotfiles/.config/starship.toml` were removed.

**Closed (2026-08-16, two passes):** every themeable tool in debian's own
`chezmoi/dot_config/colorice/templates/` (23 files, the authoritative list
of what debian actually themes) that has an arch-dotfiles equivalent
package is now themed here — full cross-reference swept, not just the
three flagged after the first ricing pass:

bat, eza, git-delta (`.gitconfig`), fzf, tmux, zsh-syntax-highlighting,
btop, cava, mangohud, yazi, lazygit, zathura, mpv/uosc, newsboat, aerc,
atuin, ncspot, cmus, calcurse, taskwarrior (`.taskrc`), zellij (added to
`packages/pacman.txt`, was never ported at all), ducker (missed in the
first ricing pass), fastfetch, rtorrent, starship, bluetuith, glow (all
five missed in the first ricing pass — installed but unthemed). Also
`ttf-cascadia-mono-nerd` added to `packages/pacman.txt` (`hypr.theme`
referenced `CaskaydiaCove Nerd Font Mono` but nothing installed it).

Config schemas verified two ways: against the tool's own real upstream
docs/source (zellij, bluetuith, ducker, glow) where debian's version
needed independent confirmation, or ported directly from debian's own
already-working `colorice` templates (fastfetch, rtorrent, starship, glow)
with palette placeholders substituted for the canonical Monokai Pro hex
values.

**Deliberately deferred per the ricing spec** (not gaps, tracked
decisions):
- Icon theme (debian: Papirus + Catppuccin folder recolor) — out of scope,
  relies on wallbash's dynamic GTK/Qt recolor instead of a bundled icon set.
- Cursor theme (debian: Bibata, live-recolored per-hex) — `hypr.theme`
  references `Bibata-Modern-Ice` as a placeholder name only; the actual
  package/theme isn't installed or verified.
- Real wallpaper — `wall.png` is a flat `#2d2a2e` placeholder, same
  pattern as `monitors.conf`, pending real hardware.
- GRUB boot theme — CachyOS may default to a different bootloader
  (systemd-boot is common on Arch-based installers); verify what's
  actually in use before assuming GRUB applies at all.
- qt5ct/GTK palette — relies on HyDE's wallbash `gtk-css.dcol`/qtct
  templates recoloring from `theme.dcol` automatically; not hand-verified
  against a running system.
- Zen Browser CSS theming (debian: `zen-colors.css`, imported via
  `userChrome.css` in the browser's profile) — Zen Browser has no viable
  TUI replacement (kept as GUI, see the earlier GUI→TUI swap round) and
  its per-profile flatpak-sandbox CSS injection is a different mechanism
  than the CLI/TUI config-file pattern this ricing pass covers — out of
  scope, not attempted.
- `wtf.yml` (a terminal dashboard tool) — `wtf` itself was never added to
  `packages/`, so nothing to theme; not confirmed wanted.

## 3. Dropped on purpose (non-FOSS), not a gap

- **google-chrome-stable** — proprietary; Zen Browser (flatpak, already in
  README's not-automated list) replaces it, same call debian made.
- **VS Code** (`code`) — proprietary build + telemetry; Neovim is the sole
  editor, same call debian made.

## 4. Carried over unresolved from debian itself

debian-dotfiles never installed these either (raised, not confirmed
wanted, or blocked on its own apt mirror) — still open, still nothing
here for them:

- scrcpy — was failing to resolve on debian's apt mirror; untested on Arch/AUR
- openrgb, reaper — no install task in debian either
- LocalSend, HandBrake, ProtonUp-Qt, protontricks, lutris — raised during
  debian's oldpackages review, never confirmed wanted
- ollama — raised, not confirmed wanted
- gurk (Signal), Posting (HTTP client) — surfaced from a TUI-apps search,
  never confirmed wanted

`barrier` is not listed here — debian already replaced it with
`input-leap` (flatpak), which arch-dotfiles' README already carries
forward under "Not automated yet."
