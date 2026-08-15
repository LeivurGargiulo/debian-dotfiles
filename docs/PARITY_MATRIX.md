# Parity matrix — Debian/Plasma 6 rebuild

One row per desktop/app function. `Sources` lists which prior-machine
history or parity target justified including it: `GNOME` (desktop-shell
parity target), `Arch` (oldpackages/pkglist.txt + installed.txt, prior
CachyOS machine), `PopOS` (oldpackages/apt-history.txt +
flatpak-apps.txt), `Win` (oldpackages/windows-inventory/).

| Function | Chosen tool | Type | Sources |
|---|---|---|---|
| App launcher | KRunner (Plasma built-in) | GUI (keyboard-driven overlay) | GNOME |
| Notifications | Plasma notification system | GUI (built-in) | GNOME |
| Status bar | Plasma panel | GUI (bar) | GNOME, Arch |
| File manager | yazi | TUI | GNOME, Arch |
| System monitor | btop | TUI | GNOME, Arch, PopOS |
| Network manager | plasma-nm (built-in applet) | GUI | GNOME |
| Bluetooth | bluedevil (built-in applet) | GUI | GNOME |
| Clipboard manager | Klipper (Plasma built-in) | GUI | GNOME, Arch |
| Screenshot | spectacle | GUI | PopOS, Win |
| Archive tool | thunar-archive-plugin + unzip/7z | GUI+CLI | Arch, Win |
| PDF viewer | zathura | TUI-adjacent | Arch |
| Torrent client | qbittorrent | GUI | Arch, PopOS |
| Remote desktop | remmina | GUI | Arch |
| Android screen mirror/control | scrcpy | CLI/GUI (window) | user request |
| Music player | ncspot | TUI | Win (Spotify) |
| Video editor | kdenlive | GUI | Arch, PopOS, Win |
| Audio production | FL Studio (via Wine/Bottles, out of scope here) | GUI | Win |
| Raster editor | gimp | GUI | Arch, PopOS, Win |
| Screen recording | obs-studio | GUI | Arch, PopOS, Win |
| Gaming | steam (+ steam-tui launcher) | GUI+TUI | Arch, Win |
| Editor | Neovim (NvChad) | TUI | GNOME, all |
| Terminal multiplexer | tmux (gpakosz base) | TUI | GNOME |
| Terminal emulator | kitty | GUI (kept from repo) | GNOME |
| Wallpaper | Plasma wallpaper (System Settings) | GUI (built-in) | GNOME |
| Idle/lock | KWin (built-in idle + lock screen) | GUI (built-in) | GNOME |
| Compositor | KWin (built-in, blur/shadow/rounded corners) | GUI (built-in) | GNOME |
| Volume/brightness OSD | Plasma OSD (built-in) | GUI (built-in) | GNOME |
