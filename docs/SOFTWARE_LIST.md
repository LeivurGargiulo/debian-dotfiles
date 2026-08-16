# Software list

Everything `install.sh` installs, grouped by category and purpose — same
spirit as `debian-dotfiles/docs/SOFTWARE_LIST.md`. Source of truth is
`packages/pacman.txt` / `packages/aur.txt`; regenerate this list by hand if
those change, it's a snapshot, not a generated artifact.

## AMD Wayland GPU stack (`packages/pacman.txt`)

| Package | Purpose |
|---|---|
| mesa | open-source graphics driver stack (OpenGL/Vulkan) |
| vulkan-radeon | Vulkan driver for AMD GPUs (RADV) |
| vulkan-icd-loader | Vulkan loader, dispatches to the installed ICD |
| libva-mesa-driver | VA-API hardware video decode/encode via Mesa |
| mesa-vdpau | VDPAU hardware video decode via Mesa |

## Core CLI (`packages/pacman.txt`)

| Package | Purpose |
|---|---|
| curl | HTTP client, scripting/downloads |
| eza | modern `ls` replacement (icons, git status, tree view) |
| bat | `cat` with syntax highlighting and git integration |
| fd | fast, friendly `find` replacement |
| ripgrep | fast recursive grep |
| fzf | fuzzy finder, used interactively and by shell/tool integrations |
| zoxide | frecency-based `cd` replacement |
| tmux | terminal multiplexer |
| mosh | roaming, lag-resistant SSH replacement |
| jq | JSON processor for scripting |
| git | version control |
| github-cli | `gh` — GitHub from the terminal (PRs, issues, releases) |
| zsh | shell |
| p7zip | 7-Zip archive support |
| unrar | RAR archive extraction |
| ffmpeg | audio/video transcoding library and CLI |
| python | Python interpreter |
| python-pip | Python package installer |
| jdk-openjdk | Java Development Kit |
| openssh | SSH client/server |
| docker | container runtime |
| docker-compose | multi-container Docker orchestration |
| unzip | ZIP archive extraction |
| imagemagick | image conversion/manipulation CLI |
| git-delta | syntax-highlighting pager for git diffs |
| duf | disk usage/free space, `df` replacement |
| smartmontools | disk S.M.A.R.T. health monitoring |
| hdparm | disk/SSD low-level parameter tuning |
| ncdu | interactive disk usage analyzer |
| btop | resource monitor (CPU/mem/disk/net/proc) |
| chafa | terminal image/GIF viewer |
| lftp | scriptable SFTP/FTP client |
| rclone | cloud storage sync (Nextcloud/WebDAV/S3/etc) |
| wl-clipboard | Wayland clipboard CLI (`wl-copy`/`wl-paste`) |
| playerctl | media-key control for MPRIS players |
| udiskie | USB drive automount daemon |
| newsboat | TUI RSS reader |
| cmus | console music player |
| oath-toolkit | TOTP/HOTP 2FA code generator |
| taskwarrior | CLI task manager |
| calcurse | TUI calendar/scheduler |
| yt-dlp | YouTube/video-site downloader |
| atuin | shell history sync + searchable TUI |
| lazygit | TUI for git |
| yazi | TUI file manager |
| neovim | text editor |
| fastfetch | system info banner |
| pulsemixer | PulseAudio/PipeWire mixer TUI |
| aerc | TUI email client |
| git-filter-repo | rewrite git history (branch/file surgery) |
| jrnl | CLI journal/diary |

## TUI-first picks (`packages/pacman.txt`)

| Package | Purpose |
|---|---|
| zathura | keyboard-driven PDF viewer |
| zathura-pdf-mupdf | zathura's PDF rendering backend (mupdf) |
| mpv | video/audio player |
| rtorrent | BitTorrent client with an ncurses TUI |
| cava | terminal audio visualizer |

## Firewall / disk (`packages/pacman.txt`)

| Package | Purpose |
|---|---|
| ufw | simple firewall front-end for iptables/nftables |
| gparted | GUI partition editor |

## GUI apps, no TUI equivalent (`packages/pacman.txt`)

| Package | Purpose |
|---|---|
| remmina | RDP/VNC remote desktop client |
| gimp | image editor |
| kdenlive | video editor |
| obs-studio | screen recording/streaming |
| libnotify | desktop notification library other apps depend on |

## Gaming (`packages/pacman.txt`, multilib)

| Package | Purpose |
|---|---|
| steam | game store/launcher/runtime |
| mangohud | in-game FPS/perf overlay |

## Flatpak runtime (`packages/pacman.txt`)

| Package | Purpose |
|---|---|
| flatpak | sandboxed app runtime — see README's "Not automated yet" for apps installed on top (Zen Browser is native AUR though, see below) |

## Shell environment (`packages/pacman.txt` + `packages/aur.txt`)

| Package | Purpose |
|---|---|
| zsh-autosuggestions | fish-style command autosuggestions for zsh |
| zsh-syntax-highlighting | real-time command syntax highlighting for zsh |
| zsh-completions | extra completion definitions for zsh |
| zsh-history-substring-search | up/down arrow history search by substring |
| oh-my-zsh-git (AUR) | zsh configuration framework, hosts the plugins above |
| tmux-plugin-manager (AUR) | plugin manager for tmux |
| zsh-theme-powerlevel10k (AUR) | zsh prompt theme, see `dotfiles/.p10k.zsh` |

## Misc, official repos (`packages/pacman.txt`)

| Package | Purpose |
|---|---|
| tailscale | mesh VPN |
| uv | Python package/project manager |
| rustup | Rust toolchain installer |
| nvm | Node Version Manager |
| zellij | terminal workspace/multiplexer (tmux alternative) |
| ttf-firacode-nerd | FiraCode font patched with Nerd Fonts glyphs, terminal/code font |
| yarn | JS package manager, build dependency for the Monokai Pro cursor theme (`scripts/build-monokai-cursor.sh`) |
| papirus-icon-theme | icon theme, recolored per-folder to Monokai Pro by `scripts/build-monokai-icons.sh` |
| firefox | web browser, themed via `scripts/apply-firefox-theme.sh` (`firefox/userChrome.css`), replaces Zen Browser |

## Python libraries, system-wide (`packages/pacman.txt` + `packages/aur.txt`)

Replaces what used to be user-scoped `pip install`s in the prior (Debian)
setup — see `docs/debian-parity-gaps.md` for why these moved to system
packages.

| Package | Purpose |
|---|---|
| python-beautifulsoup4 | HTML/XML parsing |
| python-curl_cffi | curl-backed HTTP client that mimics browser TLS fingerprints |
| python-dateutil | date/time parsing and arithmetic extensions |
| python-dotenv | load `.env` files into environment variables |
| python-numpy | numerical arrays/linear algebra |
| python-pandas | dataframes / tabular data analysis |
| python-peewee | small ORM |
| python-pillow | image processing library |
| python-prompt_toolkit | build interactive CLI prompts/REPLs |
| python-protobuf | Protocol Buffers serialization |
| python-pyarrow | Apache Arrow columnar data / Parquet |
| python-pytest | test framework |
| python-pytz | timezone database |
| python-questionary (AUR) | interactive CLI prompts (menus, checkboxes) |
| python-six | Python 2/3 compatibility shims (dependency of older libs) |
| python-soupsieve | CSS selector engine (beautifulsoup4 dependency) |
| python-sqlalchemy | SQL toolkit / ORM |
| python-websockets | WebSocket client/server library |

## ratatui TUI picks (`packages/pacman.txt` + `packages/aur.txt`)

Curated from [awesome-ratatui](https://github.com/ratatui/awesome-ratatui) — see
`docs/superpowers/plans/2026-08-16-monokai-pro-ricing.md` for the selection
process.

| Package | Purpose |
|---|---|
| bottom | graphical process/system monitor, alt to btop |
| dua-cli | interactive disk usage analyzer/cleaner |
| diskonaut | disk usage treemap navigator |
| systemctl-tui | TUI for browsing/controlling systemd units |
| gitui | fast terminal UI for git |
| trippy | combined traceroute + ping network diagnostic TUI |
| gping | `ping` with a live graph |
| serie | interactive git commit graph viewer |
| igrep | ripgrep-powered interactive search browser |
| tabiew | CSV viewer with SQL-like querying |
| rucola | markdown Zettelkasten note manager |
| mirro-rs-git (AUR) | Arch Linux mirrorlist manager TUI |
| parui (AUR) | TUI front-end for the `yay`/`paru` AUR helper |
| journalview (AUR) | `journalctl` log viewer TUI |
| hwatch (AUR) | `watch` replacement with history/diff between runs |
| doxx-git (AUR) | terminal viewer for `.docx` files |
| bookokrat-bin (AUR) | terminal ebook reader (EPUB/PDF/Markdown) |

## TUI replacements for GUI apps (`packages/aur.txt`)

Researched swaps for GUI apps that had a genuinely viable TUI equivalent —
see `docs/debian-parity-gaps.md` and the brainstorm history for what was
ruled out and why.

| Package | Purpose |
|---|---|
| claude-squad-bin | manage multiple concurrent Claude Code (and other agent CLI) sessions across git worktrees via tmux |
| endcord | Discord TUI client, replaces Vesktop |
| nchat | Telegram/WhatsApp/Signal TUI client, replaces Telegram Desktop + ZapZap |
| vm-curator-bin | libvirt/QEMU-KVM VM manager TUI, replaces GNOME Boxes |

## AMD GPU monitor (`packages/aur.txt`)

| Package | Purpose |
|---|---|
| amdgpu_top | AMD GPU usage/clock/power monitor |

## CLI/TUI tools, AUR-only (`packages/aur.txt`)

| Package | Purpose |
|---|---|
| ncspot | Spotify TUI client |
| bandwhich | per-process network bandwidth monitor |
| bluetuith | Bluetooth manager TUI |
| glow | terminal markdown renderer |
| ducker | Docker/Compose management TUI |
| taskwarrior-tui | interactive TUI front-end for taskwarrior |
| gophertube | YouTube search/browse TUI (plays via mpv) |
| wden | dedicated Bitwarden vault-browser TUI |
| ytfzf | fuzzy-search and play YouTube videos via mpv |
| tremc | Transmission remote-control TUI |

## Password / 2FA (`packages/aur.txt`)

| Package | Purpose |
|---|---|
| rbw | unofficial Bitwarden CLI/agent, holds unlocked vault in memory |
| rofi-rbw | rofi front-end for rbw, quick password lookup |
| bitwarden-cli-bin | official Bitwarden CLI (prebuilt binary via AUR) |

## Dev tools, unofficial AUR builds (`packages/aur.txt`)

| Package | Purpose |
|---|---|
| claude-code | community-maintained AUR build of Claude Code — see README for the trust caveat (not published by Anthropic) |

## Browsers / chat, AUR -bin builds (`packages/aur.txt`)

| Package | Purpose |
|---|---|
| rustdesk-bin | ad-hoc P2P remote desktop access |

## Monokai Pro cursor/icon theme build tooling (`packages/aur.txt`)

| Package | Purpose |
|---|---|
| python-clickgen | provides `ctgen`, builds the Monokai Pro cursor theme (`scripts/build-monokai-cursor.sh`) |
| papirus-folders | recolors Papirus folder icons, used by `scripts/build-monokai-icons.sh` |

## Gaming / disk tools, AUR -bin builds (`packages/aur.txt`)

| Package | Purpose |
|---|---|
| steam-tui-bin | TUI wrapper/launcher around a Steam library |
| ventoy-bin | multi-ISO bootable USB creator |

## Not automated (see README's "Not automated yet")

- Flatpak GUI apps: EasyEffects, PrismLauncher, input-leap, osu!
- `@anthropic-ai/claude-code` (npm) — kept as the official install path
  deliberately, alongside the unofficial AUR `claude-code` above
- `nvm`-installed Node LTS — a runtime operation, not a package
