#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_file="$repo_root/install.log"
: > "$log_file"
exec > >(while IFS= read -r line; do printf '[%(%H:%M:%S)T] %s\n' -1 "$line"; done | tee -a "$log_file") 2>&1

trap 'ec=$?; if [[ $ec -ne 0 ]]; then echo "==> FAILED (exit $ec): \"$BASH_COMMAND\" at line $LINENO — see $log_file" >&2; else echo "==> SUCCESS — full log at $log_file"; fi' EXIT

if [[ "$EUID" -eq 0 ]]; then
    echo "error: do not run install.sh as root" >&2
    exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
    echo "error: pacman not found — this script targets Arch-based distros (CachyOS)" >&2
    exit 1
fi

echo "==> checking base dependencies (git, base-devel)"
sudo pacman -S --needed --noconfirm git base-devel

if ! command -v yay >/dev/null 2>&1; then
    echo "==> bootstrapping yay (AUR helper)"
    tmp_yay="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp_yay/yay-bin"
    (cd "$tmp_yay/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp_yay"
fi

echo "==> installing packages/pacman.txt"
grep -vE '^\s*#|^\s*$' "$repo_root/packages/pacman.txt" | sudo pacman -S --needed --noconfirm -

echo "==> installing packages/aur.txt"
grep -vE '^\s*#|^\s*$' "$repo_root/packages/aur.txt" | yay -S --needed --noconfirm -

echo "==> installing Node LTS via nvm"
export NVM_DIR="$HOME/.nvm"
set +u
# shellcheck disable=SC1091
source /usr/share/nvm/init-nvm.sh
nvm install --lts
set -u

echo "==> running vendor/hyde/Scripts/install.sh (HyDE's own installer)"
(cd "$repo_root/vendor/hyde/Scripts" && ./install.sh)

echo "==> applying dotfiles overlay (scripts/symlink-dotfiles.sh)"
"$repo_root/scripts/symlink-dotfiles.sh"

echo "==> building Monokai Pro cursor theme (Bibata via cbmp)"
"$repo_root/scripts/build-monokai-cursor.sh"

echo "==> building Monokai Pro icon theme (Papirus folders)"
"$repo_root/scripts/build-monokai-icons.sh"

echo "==> applying Monokai Pro HyDE theme"
if command -v hydectl >/dev/null 2>&1; then
    hydectl theme set "Monokai-Pro"
fi

echo "==> applying Monokai Pro Firefox theme"
"$repo_root/scripts/apply-firefox-theme.sh"

cat <<'EOF'

==> done.

Reminder: dotfiles/.config/hypr/monitors.conf is a placeholder.
Once on real hardware, run `hyprctl monitors`, fill in real output
names/positions in that file, then re-run:
  scripts/symlink-dotfiles.sh
(or re-run install.sh — it's safe to re-run end to end)
EOF
