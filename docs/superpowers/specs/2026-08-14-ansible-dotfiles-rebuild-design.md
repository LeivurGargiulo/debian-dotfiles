# Debian rebuild: Ansible + chezmoi + Catppuccin Mocha, TUI-first

Ground-up redesign of the WSL-to-Debian migration tooling. Supersedes the
prior stow+numbered-bash-scripts+Gruvbox repo at `~/dotfiles` (moved aside to
`~/dotfiles-old` as part of implementation — see "Migration from old repo"
below). Goal unchanged: `git clone` + one command on a fresh Debian box
reaches a fully configured, fully themed machine — but every tooling choice
was reconsidered from scratch rather than carried forward by default.

## Why rebuild instead of fix

The old repo was reported broken and abandoned rather than debugged (user's
call — out of scope to investigate what broke). Rather than patch it, this
design reconsiders each structural choice independently: orchestration
engine, dotfile-linking method, and package tracking format all changed.

## Architecture

**Repo layout**: single repo (chezmoi source lives inside the Ansible
repo, not split out) — one clone, one entrypoint.

**Orchestration**: Ansible playbook (`site.yml`), roles per concern:

- `packages` — apt/flatpak/GitHub-release/official-script installs, driven
  by `group_vars/all/packages.yml`
- `desktop` — KDE Plasma 6 base + KWin-scripted tiling layer (Bismuth or
  Polonium — not a separate WM swap)
- `theme` — Catppuccin Mocha color scheme, icons, cursor, fonts, wallpaper,
  panel widgets
- `dotfiles` — invokes `chezmoi apply` against this repo's chezmoi source dir
- `shell-env` — oh-my-zsh, atuin, fzf, nvm+node, tmux plugin manager
- `dev-tools` — pip-user packages, npm-global, lazygit, language toolchains

Ansible's native idempotency (`--check` for dry-run, task-level
change-detection) replaces the old repo's manually-written re-run safety.

**Dotfile linking**: chezmoi. Directory mirrors `$HOME`'s structure via
chezmoi's source-state convention (`dot_zshrc`, etc). Secrets (SSH host
aliases, Tailscale IPs) stored age-encrypted using chezmoi's built-in
encrypted-file support — repo is safe to push even if made public.

**Testing**: VirtualBox/QEMU Debian VM, snapshotted before each playbook run
for repeatable clean-slate testing. Covers the full GUI/login-manager path
that WSL testing (the old repo's method) could not — sddm, KWin compositor
blur, and Plasma theming all need a real display manager to verify.

**Bootstrap on fresh machine**:

```sh
sudo apt install ansible git
git clone <repo> ~/dotfiles && cd ~/dotfiles
ansible-playbook site.yml --ask-become-pass
```

## Desktop environment

KDE Plasma 6 as base DE (native KWin compositor, sddm login manager,
Wayland). Tiling added via a KWin scripting extension (Bismuth or Polonium
— final pick deferred to implementation, both are apt/AUR-adjacent
installable and give i3-style keyboard tiling without replacing KWin as the
compositor). This is a hybrid choice deliberately: DE-level GUI safety net
(Settings app, native notifications, sddm) plus keyboard-driven tiling
workflow, without hand-assembling a bar/launcher/notification-daemon stack
piece by piece (the approach the old i3wm-era rebuild attempt in this
project's history ran into unfinished/buggy UI pieces with).

## Theming

- **Palette**: Catppuccin Mocha, applied as the global Plasma color scheme.
- **Icons**: Papirus + `catppuccin-papirus-folders` accent overlay.
- **Cursor**: `catppuccin-cursors`.
- **Fonts**: JetBrainsMono Nerd Font, terminal + UI.
- **Wallpaper**: pulled from the `catppuccin/wallpapers` repo (Mocha-tagged
  set), applied at install time via `plasma-apply-wallpaperimage` — not a
  manual post-install step.
- **Panel**: stock Plasma panel + KRunner (not swapped for a dock), extended
  with two KDE Store community widgets — a system-monitor applet and a
  media-controls applet.
- **Terminal**: kitty, Catppuccin Mocha palette, glassy look carried over
  from the old repo's aesthetic (`background_opacity 0.85`,
  `background_blur 24`) — this time via KWin's compositor blur rather than
  SwayFX (the old repo's terminal README noted the effect was
  Sway-compositor-specific; Plasma's KWin supports blur-behind natively, so
  the effect is portable, just needs re-verifying against KWin's blur
  implementation during implementation).
- **Prompt**: starship, Catppuccin Mocha preset (starship ships one).

The `theme` Ansible role owns all of the above: color-scheme apply,
icon/cursor/font package install, wallpaper fetch+set,
KDE Store widget install (`kpackagetool6` or manual `.plasmoid` drop),
kitty/starship config delivered via chezmoi.

## Package selection

TUI-first per explicit direction: pick a TUI tool over a GUI one wherever a
mature TUI option exists and covers the job. GUI is kept only where no
TUI equivalent exists (image/video editing, gaming storefronts, RDP/VNC,
office-adjacent apps). Full inventory reviewed: old repo's `apt.txt`,
`oldpackages/` (two prior Linux machines' package dumps — Pop!_OS apt lists
and a CachyOS/Arch `pkglist.txt` — plus a Windows `Get-Package` dump and a
wishlist file), and this conversation's category-by-category walkthrough.

### TUI-first picks

| Category | Tool |
|---|---|
| File manager | yazi |
| System monitor | btop |
| Disk usage | ncdu (+ duf for quick overview) |
| Network bandwidth | bandwhich |
| Bluetooth | bluetuith |
| Git | lazygit |
| Notes/journal | jrnl |
| Markdown render | glow |
| PDF | zathura |
| Media playback | mpv |
| Music (Spotify) | ncspot |
| Torrent | transmission-cli + tremc |
| Video download | yt-dlp |
| Remote/headless monitoring | glances (`--webserver` mode) |
| Shell history | atuin |
| Audio visualizer | cava |
| Editor | nvim (NvChad config, carried from old repo) |

### Deliberate GUI exceptions (no viable TUI equivalent)

Dolphin (file-manager fallback), vesktop (Discord — no TUI Discord client
exists), remmina + plugins (RDP/VNC — inherently graphical), gimp, kdenlive,
obs-studio, steam (+ MangoHud overlay, Proton version manager — gaming
storefronts are DRM'd GUIs by nature), nextcloud-desktop, filezilla, VS Code
(kept alongside nvim for IDE-style work — debugging, extensions), Telegram
desktop, ZapZap (WhatsApp wrapper), Bitwarden (CLI-first but has a GUI/
browser-extension component), pavucontrol + EasyEffects, GNOME Boxes
(virtualization), OpenRGB (motherboard is Gigabyte per the Windows
inventory — no official Linux vendor tool exists), Gwenview (image viewer),
Ventoy (USB flashing), Reaper (native DAW) + FL Studio via Wine/Bottles
(no native Linux FL Studio — kept both: Reaper for Linux-native work, Wine
for the exact familiar FL Studio workflow when needed), Prism Launcher
(Minecraft), Barrier (keyboard/mouse sharing across two machines — distinct
job from remote desktop), ufw (firewall — has a CLI but is conceptually a
background service, not TUI-interactive).

### Explicitly skipped

Office suite (LibreOffice/ONLYOFFICE — not needed), dedicated email client
(webmail instead), Zoom (browser instead), local LLM/Ollama, ProtonVPN
(Tailscale already covers the mesh-networking need), JetBrains IDEs
(VS Code + nvim covers it), Ark/GUI archive manager (CLI 7z/unzip via yazi
covers it), udiskie (Plasma auto-mounts natively, udiskie is for bare-WM
setups like the old repo's i3/Hyprland attempts).

### Language package lists

`packages/pip-user.yml` (Ansible-vars form, not flat text): carries over
the old repo's list minus the finance-specific stack —
**dropped**: `yfinance`, `pandas-ta-classic`. **Kept**: `beautifulsoup4`,
`curl_cffi`, `git-filter-repo`, `numpy`, `pandas`, `peewee`, `pillow`,
`prompt_toolkit`, `protobuf`, `pyarrow`, `python-dateutil`,
`python-dotenv`, `pytz`, `questionary`, `SQLAlchemy`, `six`, `soupsieve`,
`websockets`, `pytest`.

`packages/npm-global.yml`: empty placeholder, matching the old repo (no
custom global npm tools were ever actually installed).

## Shell environment

Carried forward verbatim from the old repo's `shell/.zshrc` (already
extracted from the live WSL box, not re-derived): oh-my-zsh with
`git sudo extract zsh-autosuggestions zsh-syntax-highlighting
zsh-completions zsh-history-substring-search`, eza/bat/fd-find Debian-name
aliasing, zoxide (`cd`→`z`, `cdi`→`zi`), fzf key-bindings, quick-nav
aliases. **Addition**: atuin layered in for fuzzy-searchable shell history
(was used on the old CachyOS machine but never carried to WSL). This
becomes chezmoi source content (`dot_zshrc`), not hand-copied at install
time — editing it in the repo is editing the live config.

## Secrets and machine-specific config

SSH host aliases and Tailscale IPs (currently in the old repo's
`dev/.ssh/config`, 12 lines) move into chezmoi's encrypted-file mechanism
(age or gpg backend — pick during implementation based on whether an
existing GPG key should be reused). Claude Code global config (`CLAUDE.md`,
`RTK.md`, hooks, skills, agents) keeps the old repo's deliberate
not-fully-automated treatment: reference copies tracked in the repo,
reapplied manually to `~/.claude/` post-install, since `~/.claude/` holds
credentials and session state that scripted overwrites risk clobbering.

## Migration from old repo

The old `~/dotfiles` repo is archived aside (moved to `~/dotfiles-old`,
kept for reference/salvage, not deleted) once the new repo is scaffolded.
This spec's own file currently lives inside the old repo's
`docs/superpowers/specs/` — the implementation plan should carry it (and
any other still-relevant docs, e.g. `PARITY_MATRIX.md` app-list source
material) into the new repo's `docs/` during scaffolding, then perform the
archive move.

## Testing plan

1. Spin up a fresh Debian VM (VirtualBox/QEMU), snapshot at clean-install
   state.
2. Run `ansible-playbook site.yml --check` (dry-run) first to catch
   obviously wrong task definitions before mutating anything.
3. Run for real, verify: package installs succeed (individually-retried,
   matching old repo's resilience — one bad package name shouldn't abort
   the run), Plasma+tiling+Catppuccin theme applies and renders correctly
   post-reboot through sddm, chezmoi-managed dotfiles land correctly in
   `$HOME`, secrets decrypt correctly.
4. Roll back to snapshot, re-run from clean state to verify idempotency
   end to end (not just per-task `--check` idempotency).
5. Repeat on real hardware only after VM testing passes — matches the old
   repo's finding of two real bugs only surfacing on bare metal (Plasma
   packages, flameshot/Wayland incompatibility), so a bare-metal pass
   stays part of the plan even after VM success.
