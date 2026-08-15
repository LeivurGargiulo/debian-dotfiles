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
sync), pulsemixer (PulseAudio mixer)

## TUI-first picks (`apt_packages`)

zathura (PDF), mpv (video), transmission-cli (torrent), cava (audio
visualizer)

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

## Installed via official install scripts (`official_scripts.yml`)

- starship (prompt)
- tailscale (VPN)
- chezmoi (dotfile manager — this repo's config is applied by it)

## Flatpak apps (`flatpak_apps`, via Flathub)

- Zen Browser (FOSS Firefox fork, replaces Google Chrome — see Not FOSS /
  removed below)
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
websockets, pytest, tremc

## npm global packages (`npm_global_packages`)

@bitwarden/cli

## Shell environment (`shell-env` role, not apt/pip/npm)

- oh-my-zsh (+ zsh set as default shell)
- zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions,
  zsh-history-substring-search (oh-my-zsh custom plugins)
- nvm + latest Node LTS
- tmux plugin manager (tpm)

## Vendored dotfile configs (chezmoi, not installed packages)

Config only, application itself installed above: i3, polybar, rofi,
picom, dunst, fastfetch, kitty, neovim (kickstart.nvim fork), yazi
(with the `catppuccin-mocha` flavor).

## Not automated (known gap, see `packages.yml` comment block)

- scrcpy — not resolving on this apt mirror, check `sources.list`
- jrnl, glow, mangohud, openrgb, reaper — no install task anywhere in
  this repo yet, install manually if needed
- barrier — dropped, unmaintained upstream; input-leap (flatpak, above)
  replaces it

## Dropped for non-FOSS / build-size (this pass)

- **google-chrome-stable** (proprietary) — replaced by Zen Browser
  (flatpak, above). Its custom apt repo/key setup
  (`ansible/roles/packages/tasks/apt_repos.yml`) is deleted entirely.
- **code** (Microsoft's VS Code build — proprietary license + telemetry)
  — dropped outright, no GUI editor replacement. Neovim (in
  `i3_packages`) is the sole editor.
