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

## 2. Theming/config layer — pending the ricing task, not blocked

All of debian's Catppuccin theming (Papirus icons + folder recoloring,
Bibata cursor theme, CaskaydiaCove Nerd Font, wallpaper, qt5ct/GTK palette,
per-tool Catppuccin configs for bat/delta/eza/fzf/tmux/btop/cava/zathura/
mpv/newsboat/aerc/atuin/ncspot/lazygit/zellij/ducker/zen-browser/vesktop/
zsh-syntax-highlighting/mangohud/GRUB) is **config**, not packages — it
belongs in the `dotfiles/` overlay, same mechanism as
`dotfiles/.config/hypr/monitors.conf`. Nothing to add to `packages/`;
this is the "ricing" task, not a package gap.

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
