# Software list

Everything this repo's Ansible playbook installs, grouped by how it gets
installed. Source: `ansible/group_vars/all/packages.yml` and the role
task files under `ansible/roles/`. Regenerate this list by hand if those
files change — it's a snapshot, not a generated artifact.

## Desktop stack (`i3_packages`, installed by the `desktop` role)

| Package | Purpose |
|---|---|
| xserver-xorg, xinit | X11 server |
| i3-wm | tiling window manager |
| i3lock | screen locker |
| polybar | status bar |
| rofi | app launcher / power menu |
| picom | compositor (shadows, transparency) |
| dunst | notification daemon |
| lightdm, lightdm-gtk-greeter | display manager / login screen |
| network-manager-gnome | nm-applet (tray network icon) |
| blueman | Bluetooth tray applet |
| flameshot | screenshot tool |
| lxpolkit | GUI polkit auth agent |
| lxappearance | GTK theme switcher |
| qt5ct | Qt app theme config |
| thunar, thunar-archive-plugin | file manager |
| nitrogen | wallpaper setter |
| dex | autostart .desktop file runner |
| light | screen brightness control |
| pulseaudio-utils | audio control CLI |
| neovim | editor (also see dotfile config below) |
| fastfetch | system info banner |

**picom is no longer in this list** — it's built from source (see
"Built from source" below) since the animation-fork used here has no
Debian package. `greenclip` (clipboard manager) and
`betterlockscreen` (screen lock) are also new to the desktop stack but
installed differently — see their own sections below. All three are
documented in [DESKTOP_GUIDE.md](DESKTOP_GUIDE.md) and
[KEYBINDINGS.md](KEYBINDINGS.md).

## Built from source (`ansible/roles/desktop`)

- **picom** (`pijulius/picom`, `implement-window-animations` branch) —
  compositor with window-animation support the stock apt package
  lacks. Build deps declared as `picom_build_deps` in `packages.yml`
  (meson/ninja + the usual X11/xcb/pixman headers). Installed to
  `/usr/local/bin/picom`, shadowing the apt package name if one is
  ever reinstalled — check `which picom` if behavior looks wrong.

## Fetched scripts (`ansible/roles/desktop`)

- **betterlockscreen** — no packaged release asset, fetched as a raw
  script from its GitHub `main` branch to `/usr/local/bin`. Config:
  `chezmoi/dot_config/betterlockscreen/betterlockscreenrc`.

## Theming (`theme_packages` + fetched assets, `theme` role)

- papirus-icon-theme, qt-style-kvantum (apt)
- Catppuccin Papirus folder colors (cloned from `catppuccin/papirus-folders`)
- Catppuccin Mocha Mauve cursor theme (GitHub release zip)
- CaskaydiaCove Nerd Font (GitHub release zip)
- Catppuccin Mocha wallpaper (fetched image)
- Catppuccin Mocha Mauve Kvantum theme
- Catppuccin Mocha Mauve GTK theme (GitHub release zip)

## Core CLI tools (`apt_packages`)

curl, eza, bat, fd-find, ripgrep, fzf, zoxide, tmux, mosh, jq, git, gh,
zsh, p7zip-full, unrar-free, ffmpeg, python3, python3-pip, python3-venv,
openjdk-21-jdk, openssh-server, docker.io, docker-compose, unzip,
imagemagick, git-delta, duf, smartmontools, hdparm, ncdu, btop, chafa
(terminal image viewer), lftp (SFTP/FTP client), rclone (Nextcloud/WebDAV
sync), pulsemixer (PulseAudio mixer), mangohud (gaming perf overlay),
taskwarrior (task manager), calcurse (TUI calendar), xclip (X11
clipboard CLI), playerctl (media-key control), udiskie (USB
automount), aerc (TUI email client), newsboat (TUI RSS reader), cmus
(console music player), ytfzf (search/play YouTube via mpv), rbw
(unofficial Bitwarden CLI/agent, faster unlock than `@bitwarden/cli`),
oathtool (TOTP/HOTP code generator)

## TUI-first picks (`apt_packages`)

zathura (PDF), mpv (video), rtorrent (BitTorrent client — replaced
transmission-cli, has a built-in ncurses TUI and is packaged in apt),
cava (audio visualizer)

## Firewall / disk / archive (`apt_packages`)

ufw, gparted

## GUI apps with no TUI equivalent (`apt_packages`)

remmina, remmina-plugin-rdp, remmina-plugin-vnc, gimp, kdenlive,
obs-studio, libnotify-bin

> dolphin/gwenview/ark (KDE leftovers, redundant with Thunar), meld
> (redundant with git-delta), filezilla, nextcloud-desktop, pavucontrol,
> and glances (redundant with btop) were removed in the FOSS/build-size
> pass — see git history. filezilla → lftp, nextcloud-desktop → rclone,
> pavucontrol → pulsemixer, all listed under Core CLI tools above.

## Gaming (`apt_packages` + `github_release_binaries` + `flatpak_apps`)

- **steam-installer** (apt) — needs `contrib`/`non-free-firmware`
  components and i386 multiarch, enabled by the new
  `steam_prereqs.yml` task (untested against deb822-format
  `sources.list`, verify on bare metal)
- **mangohud** (apt) — in-game perf overlay
- **steam-tui** (GitHub release, `dmadisetti/steam-tui`) — TUI wrapper
  around your Steam library; still needs the real Steam install above,
  this is just the launcher UI. Upstream is stale (last release 2024)
- **osu!** (flatpak, `sh.ppy.osu`) — rhythm/aim-practice game
- PrismLauncher (Minecraft launcher) — already listed under Flatpak
  apps below

## Clipboard (`github_release_binaries`)

- **greenclip** — clipboard-history daemon (Haskell binary release),
  backs the `mod+c` rofi menu. Config: `chezmoi/dot_config/greenclip.toml`.

## GitHub-release binaries (`github_release_binaries`)

Installed by downloading the latest GitHub release asset straight to
`/usr/local/bin`:

- lazygit
- ncspot
- yt-dlp
- atuin
- Ventoy (Ventoy2Disk.sh)
- bandwhich
- yazi
- bluetuith
- steam-tui (see Gaming above)
- glow (TUI markdown reader)
- lazydocker (TUI for Docker/Compose, already installed under `docker.io`)
- amdgpu_top (AMD GPU monitor — AMD-hardware only)
- taskwarrior-tui (interactive TUI front-end for taskwarrior, above)
- gophertube (TUI YouTube search/browse via mpv — heavier alternative
  to ytfzf, above)
- wden (dedicated Bitwarden TUI — self-contained vault browser, works
  alongside rbw/rofi-rbw above rather than replacing them)

## Password management / 2FA (`apt_packages` + `pip_user_packages` +
`github_release_binaries` + `npm_global_packages`)

- **rbw** (apt) — unofficial Bitwarden CLI/agent, holds decrypted vault
  keys in memory after one unlock instead of re-prompting per command
- **rofi-rbw** (pip) — Rofi frontend for rbw, quick password lookups
  via the existing rofi launcher
- **wden** (GitHub release, see above) — dedicated Bitwarden TUI, full
  vault browser
- **oathtool** (apt) — TOTP/HOTP 2FA code generator
- `@bitwarden/cli` (npm, already installed) — official Bitwarden CLI,
  kept alongside rbw

## Installed via official install scripts (`official_scripts.yml`)

- starship (prompt)
- tailscale (VPN)
- chezmoi (dotfile manager — this repo's config is applied by it)
- uv (Python package/project manager, user-scoped install)
- rustup (Rust toolchain, user-scoped install — only pulled in because
  Raijin below needs `cargo install`, not used for anything else)

## Cargo packages (`cargo_packages`, via rustup above)

- Raijin (weather TUI, no API key required — only distributed via
  `cargo install`, no pre-built binary exists upstream)

## Flatpak apps (`flatpak_apps`, via Flathub)

- Zen Browser (FOSS Firefox fork, replaces Google Chrome — see Not FOSS /
  removed below)
- osu! (see Gaming above)
- RustDesk (ad-hoc P2P remote access — distinct job from Remmina's
  RDP/VNC client role above)
- Vesktop (Discord client)
- Telegram Desktop
- ZapZap (WhatsApp client)
- EasyEffects (audio effects)
- GNOME Boxes (VMs)
- PrismLauncher (Minecraft launcher)
- input-leap (KVM software, Barrier successor)

## Python packages, user-scoped pip (`pip_user_packages`)

beautifulsoup4, curl_cffi, git-filter-repo, numpy, pandas, peewee,
pillow, prompt_toolkit, protobuf, pyarrow, python-dateutil,
python-dotenv, pytz, questionary, SQLAlchemy, six, soupsieve,
websockets, pytest, tremc, jrnl

## npm global packages (`npm_global_packages`)

@bitwarden/cli, @anthropic-ai/claude-code

## Claude Code plugins/marketplaces (`claude_marketplaces` + `claude_plugins`)

Installed right after the Claude Code CLI itself, in the `dev-tools`
role: 5 plugin marketplaces (`claude-plugins-official`, `ponytail`,
`karpathy-skills`, `caveman`, `claude-community`) and 12 enabled
plugins (pyright-lsp, typescript-lsp, security-guidance, ponytail,
superpowers, context7, claude-code-setup, andrej-karpathy-skills,
caveman, playwright, serena, agnix). Full detail, plus what's vendored
from `~/.claude/` and why, in [CLAUDE_CODE_SETUP.md](CLAUDE_CODE_SETUP.md).

## Shell environment (`shell-env` role, not apt/pip/npm)

- oh-my-zsh (+ zsh set as default shell)
- zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions,
  zsh-history-substring-search (oh-my-zsh custom plugins)
- nvm + latest Node LTS
- tmux plugin manager (tpm)

## Vendored dotfile configs (chezmoi, not installed packages)

Config only, application itself installed above: i3, polybar, rofi
(+ powermenu.sh script), picom, dunst, fastfetch, kitty, neovim
(kickstart.nvim fork), yazi (with the `catppuccin-mocha` flavor),
greenclip, betterlockscreen, and Claude Code (`~/.claude/`, see
[CLAUDE_CODE_SETUP.md](CLAUDE_CODE_SETUP.md)). Full desktop behavior
write-up: [DESKTOP_GUIDE.md](DESKTOP_GUIDE.md). Every keybind:
[KEYBINDINGS.md](KEYBINDINGS.md). How to change any of this:
[CUSTOMIZING.md](CUSTOMIZING.md).

i3/polybar/rofi/picom/dunst are modeled on
[vari-sh/Catppuccin-i3-dotfiles](https://github.com/vari-sh/Catppuccin-i3-dotfiles)
(re-vendored from an earlier, differently-sourced version — see git
history "Re-vendor i3/polybar/rofi"). kitty is themed against the
official [catppuccin/kitty](https://github.com/catppuccin/kitty)
mocha.conf; fastfetch's layout is ported from
[Nukecraft5419/fastfetch](https://github.com/Nukecraft5419/fastfetch).

## Catppuccin-themed CLI/TUI tools (chezmoi, config only)

Every apt/manual-install tool with an official
[catppuccin org repo](https://github.com/orgs/catppuccin/repositories)
got Mocha theming vendored in (see git history "Catppuccin Mocha for
bat, delta, eza, fzf, tmux, ..."). Application itself installed
elsewhere in this doc — these are config-only additions:

| Tool | Config | Mechanism |
|---|---|---|
| bat | `chezmoi/dot_config/bat/` | vendored `.tmTheme`, needs `bat cache --build` once per machine |
| git-delta | `chezmoi/dot_gitconfig`, `chezmoi/dot_config/delta/` | `core.pager`/`interactive.diffFilter` + `[delta] features` — first time git itself was brought under chezmoi |
| eza | `chezmoi/dot_config/eza/theme.yml` | auto-discovered |
| fzf | `chezmoi/dot_zshrc` (`$FZF_DEFAULT_OPTS`) | no native theme file, colors are a CLI flag string |
| tmux | `chezmoi/dot_tmux.conf.local`, `chezmoi/dot_config/tmux/plugins/catppuccin/` | vendored plugin script, sourced via `run-shell` (no TPM in this repo) |
| btop | `chezmoi/dot_config/btop/` | `.theme` file + `color_theme` key |
| cava | `chezmoi/dot_config/cava/config` | inline `[color]` block |
| zathura | `chezmoi/dot_config/zathura/` | `include catppuccin-mocha` |
| mpv | `chezmoi/dot_config/mpv/mpv.conf` | OSD/UOSC color options |
| newsboat | `chezmoi/dot_config/newsboat/config` | inline `color`/`highlight` directives |
| aerc | `chezmoi/dot_config/aerc/` | styleset file + `styleset-name` key (no account config added) |
| atuin | `chezmoi/dot_config/atuin/` | theme file + `[theme]` key (no sync-server config added) |
| ncspot | `chezmoi/dot_config/ncspot/config.toml` | inline `[theme]` block (no Spotify credentials added) |
| lazygit | `chezmoi/dot_config/lazygit/config.yml` | `gui.theme` block |
| zellij | `chezmoi/dot_config/zellij/` | `.kdl` theme file + `theme` key |
| qt5ct | `ansible/roles/theme/tasks/main.yml` (NOT chezmoi) | color-scheme `.conf` fetched + `ini_file` task, alongside the existing Kvantum widget-style task |

See [CUSTOMIZING.md](CUSTOMIZING.md#add-catppuccin-theming-to-a-newly-installed-tool)
for the pattern to extend this to a new tool.

## Not automated (known gap, see `packages.yml` comment block)

- scrcpy — not resolving on this apt mirror, check `sources.list`
- openrgb, reaper — no install task anywhere in this repo yet, install
  manually if needed
- barrier — dropped, unmaintained upstream; input-leap (flatpak, above)
  replaces it
- LocalSend, HandBrake, ProtonUp-Qt/protontricks/lutris — raised during
  the oldpackages review, not confirmed wanted, left out
- ollama — raised during the oldpackages review (local LLM runner), not
  yet confirmed wanted
- gurk (Signal), Posting (HTTP client) — surfaced from the
  awesome-tuis/best-TUI-apps web search, not confirmed wanted

## Dropped for non-FOSS / build-size (this pass)

- **google-chrome-stable** (proprietary) — replaced by Zen Browser
  (flatpak, above). Its custom apt repo/key setup
  (`ansible/roles/packages/tasks/apt_repos.yml`) is deleted entirely.
- **code** (Microsoft's VS Code build — proprietary license + telemetry)
  — dropped outright, no GUI editor replacement. Neovim (in
  `i3_packages`) is the sole editor.
