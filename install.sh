#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_file="$repo_root/install.log"
: > "$log_file"
# Timestamp each line into the log (the timestamps are what make a failed run
# diagnosable afterwards) — but a plain `read` loop only ever emits a line once
# it sees a newline, and an interactive prompt never sends one. That silently
# swallowed every prompt HyDE's installer writes, so a run waiting on input
# looked exactly like a run that had hung. The `-t 1` timeout flushes whatever
# partial line is buffered, which keeps prompts visible.
exec > >(
    while true; do
        if IFS= read -r -t 1 line; then
            printf '[%(%H:%M:%S)T] %s\n' -1 "$line"
        elif (( $? > 128 )); then
            [[ -n "$line" ]] && { printf '%s' "$line"; line=""; }
        else
            [[ -n "$line" ]] && printf '%s\n' "$line"
            break
        fi
    done | tee -a "$log_file"
) 2>&1

# One scratch root for every step that needs working space, removed by the
# EXIT trap however the script ends. An explicit `rm -rf` at the end of a step
# only reclaims the space when that step succeeds, which is exactly when
# leaking a half-built checkout matters least.
#
# A single root rather than a "register each temp dir" helper on purpose: the
# obvious helper spelling, `d="$(mktemp_tracked)"`, runs the function in a
# command-substitution subshell, so the bookkeeping it does is discarded when
# that subshell exits and every directory leaks.
scratch_dir="$(mktemp -d)"
cleanup_scratch() {
    [[ -n "${scratch_dir:-}" && -d "$scratch_dir" ]] && rm -rf "$scratch_dir"
    return 0
}

# On ERR, $LINENO is the line that actually failed; in an EXIT trap it is the
# trap's own line, which is why a previous failure at line 44 reported "line 1".
trap 'ec=$?; echo "==> FAILED (exit $ec): \"$BASH_COMMAND\" at line $LINENO — see $log_file" >&2' ERR
trap 'ec=$?; cleanup_scratch; if [[ $ec -eq 0 ]]; then echo "==> SUCCESS — full log at $log_file"; fi' EXIT

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
    tmp_yay="$scratch_dir/yay"
    mkdir -p "$tmp_yay"
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp_yay/yay-bin"
    (cd "$tmp_yay/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp_yay"
fi

echo "==> full system upgrade"
# HyDE's own installer (vendor/hyde/Scripts/install_pre.sh) later runs a
# bare "sudo pacman -Syyu" with no --noconfirm, which blocks forever on
# an unattended run. Upgrading here first means that call finds nothing
# to do and never prompts.
sudo pacman -Syu --noconfirm

echo "==> installing packages/pacman.txt"
grep -vE '^\s*#|^\s*$' "$repo_root/packages/pacman.txt" | sudo pacman -S --needed --noconfirm -

echo "==> configuring the rust toolchain"
# packages/pacman.txt installs rustup, and rustup's rustc/cargo shims take
# precedence over the system ones on PATH. Until a default toolchain is
# selected those shims refuse to run at all:
#   error: rustup could not choose a version of rustc to run, because one
#          wasn't specified explicitly, and no default is configured
# which breaks every AUR package that builds with cargo. This is what killed
# the AUR step on a real CachyOS install (journalview, exit status 4), and it
# is almost certainly what the earlier "rust-lld breaks ring crate" and
# "mirro-rs-git won't link" diagnoses were actually hitting.
if command -v rustup >/dev/null 2>&1; then
    rustup default stable
fi

echo "==> installing packages/aur.txt"
# Deliberately NOT fatal. A single unbuildable AUR package used to abort the
# whole script via `set -e`, and because the AUR step sits above the HyDE
# installer that cost the entire desktop — one broken TUI toy left the machine
# on a bare TTY. Failures are collected and reported at the end instead.
aur_failed=0
grep -vE '^\s*#|^\s*$' "$repo_root/packages/aur.txt" | yay -S --needed --noconfirm - || aur_failed=1

echo "==> installing Node LTS via nvm"
export NVM_DIR="$HOME/.nvm"
set +u
# shellcheck disable=SC1091
source /usr/share/nvm/init-nvm.sh
nvm install --lts
set -u

echo "==> pre-seeding HyDE's installer (it asks four questions; this run is unattended)"

# 1. install_pre.sh rewrites /etc/pacman.conf and then runs a bare
#    "sudo pacman -Syyu" with no --noconfirm, which blocks on pacman's own
#    "Proceed with installation? [Y/n]". It skips that entire block once
#    /etc/pacman.conf.hyde.bkp exists, so take the backup and apply the same
#    edits here, where they can be done non-interactively.
if [[ ! -f /etc/pacman.conf.hyde.bkp ]]; then
    sudo cp /etc/pacman.conf /etc/pacman.conf.hyde.bkp
    sudo sed -i "/^#Color/c\Color\nILoveCandy
    /^#VerbosePkgLists/c\VerbosePkgLists
    /^#ParallelDownloads/c\ParallelDownloads = 5" /etc/pacman.conf
    sudo sed -i '/^#\[multilib\]/,+1 s/^#//' /etc/pacman.conf
fi

# 2. install_pre.sh offers Chaotic-AUR on a 120-second timer that DEFAULTS TO
#    INSTALLING IT — an unattended run silently gains a third-party repo.
#    CachyOS already ships its own tuned repos (cachyos, cachyos-znver4, ...)
#    and layering Chaotic-AUR on top is a known source of conflicting
#    rebuilds, so decline. Without hand-editing vendor/hyde the only way to
#    decline is HyDE's own guard: it skips the prompt when /etc/pacman.conf
#    already mentions [chaotic-aur], and a comment satisfies that grep
#    without enabling anything.
if ! grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
    sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

# Deliberately NOT enabling [chaotic-aur]. CachyOS ships its own tuned repos
# and layering Chaotic-AUR over them causes conflicting rebuilds. This comment
# is load-bearing: it also makes vendor/hyde's install_pre.sh skip its
# "Would you like to install Chaotic AUR?" prompt, which defaults to yes.
EOF
fi

# 3. HyDE's install.sh prompts for a shell on a 120s timer unless myShell is
#    already set. dotfiles/.zshrc is the overlay we apply, so: zsh.
export myShell=zsh

# 4. The last two direct prompts (install_pst.sh's sddm theme, and the
#    closing "reboot now?") are plain `read`s whose fall-through defaults are
#    the ones we want anyway — the Corners sddm theme, and no reboot.
#
#    Feeding stdin from /dev/null (EOF immediately) used to be how these were
#    answered, but that starves a prompt one layer deeper: HyDE's dependency
#    installer (deez) shells out to plain "sudo pacman -S <pkg>" with no
#    --noconfirm for anything it finds missing (its own package_managers
#    table has no --noconfirm entry for pacman at all). On EOF that
#    "Proceed with installation? [Y/n]" prompt fails outright, and deez only
#    logs it as "[warn] pacman: <pkg> missing" rather than treating it as
#    fatal — which is how a real run silently ended up without sddm at all
#    while still reporting success.
#
#    An endless stream of blank lines fixes both without special-casing
#    either: every prompt left in this chain — HyDE's own two, and any bare
#    pacman/makepkg confirmation deez triggers — defaults to the safe choice
#    on a bare Enter ([Y/n] proceeds, [y/N] declines, the sddm theme picker
#    falls through to Corners). It is never "y" for exactly this reason: the
#    reboot prompt is [y/N], and an unattended run must never talk itself
#    into a surprise reboot.
#
#    A partial dotfile deployment is reported by HyDE as a non-zero exit;
#    that must not cost us the overlay and theming steps below, which are
#    exactly what would repair it.
#
# Sudo's cached credential can expire mid-run — the cursor theme build alone
# takes several minutes, and combined with AUR builds a run can run long
# past the default 15-minute ticket. A background `sudo -v` every 4 minutes
# keeps it alive so a late privileged call (deez's pacman installs among
# them) never blocks on a password prompt this script has no way to answer.
sudo_keepalive_pid=""
if sudo -n true 2>/dev/null; then
    while true; do sleep 240; sudo -n true 2>/dev/null || break; done &
    sudo_keepalive_pid=$!
fi

echo "==> running vendor/hyde/Scripts/install.sh (HyDE's own installer)"
hyde_failed=0
(cd "$repo_root/vendor/hyde/Scripts" && ./install.sh < <(yes '')) || hyde_failed=1

if [[ -n "$sudo_keepalive_pid" ]]; then
    kill "$sudo_keepalive_pid" 2>/dev/null
    wait "$sudo_keepalive_pid" 2>/dev/null || true
fi

echo "==> making sddm the display manager"
# HyDE's restore_svc.sh runs a plain "systemctl enable sddm", which fails when
# another display manager already owns the display-manager.service symlink —
# e.g. a lightdm installed by hand to keep a broken machine usable. --force
# takes the symlink over, and any other enabled DM is switched off so the two
# never race for the seat.
if pacman -Qq sddm >/dev/null 2>&1; then
    for dm in lightdm gdm lxdm sddm-git; do
        if systemctl is-enabled "$dm.service" >/dev/null 2>&1; then
            echo "    disabling $dm"
            sudo systemctl disable "$dm.service"
        fi
    done
    sudo systemctl enable --force sddm.service
else
    echo "    warning: sddm is not installed — HyDE's core dependency step did not complete"
fi

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

echo "==> cleaning up build caches"
# Installing ~79 AUR packages leaves several GB of build byproducts behind:
# yay's source checkouts and build trees, plus the compiler caches the Rust
# and Go packages populate. On the fresh-reformat path this repo is built for,
# all of it is this script's own doing, and every byte of it is regenerable.
#
# install.log is deliberately NOT touched — it is the record of what this run
# did, and it is the first thing anyone needs when a run goes wrong.
if (( aur_failed )); then
    echo "    skipped: some AUR builds failed, and their cached sources make a retry"
    echo "    much faster. Re-run install.sh once they are fixed to clean up."
else
    avail_before="$(df --output=avail -k / | tail -1)"

    rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/yay"
    rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/go-build"
    # Only the download/build caches under ~/.cargo — never ~/.cargo/bin,
    # which holds anything installed with `cargo install`.
    rm -rf "$HOME/.cargo/registry" "$HOME/.cargo/git"

    # paccache ships with pacman-contrib, one of HyDE's core dependencies.
    # Keep one previous version of each installed package so a downgrade is
    # still possible, and drop cached packages that are no longer installed.
    if command -v paccache >/dev/null 2>&1; then
        sudo paccache -rk1
        sudo paccache -ruk0
    else
        echo "    note: paccache not found, leaving /var/cache/pacman/pkg alone"
    fi

    avail_after="$(df --output=avail -k / | tail -1)"
    if (( avail_after > avail_before )); then
        echo "    reclaimed $(( (avail_after - avail_before) / 1024 )) MiB"
    fi
fi

cat <<'EOF'

==> done.

Reminder: dotfiles/.config/hypr/monitors.conf is a placeholder.
Once on real hardware, run `hyprctl monitors`, fill in real output
names/positions in that file, then re-run:
  scripts/symlink-dotfiles.sh
(or re-run install.sh — it's safe to re-run end to end)
EOF

# Reported here, at the end, rather than where they happened: these steps are
# non-fatal precisely so the desktop still gets installed, but they must not
# scroll past unnoticed either.
if (( aur_failed )); then
    echo
    echo "warning: some AUR packages did not install. The rest of the install continued."
    echo "         still missing from packages/aur.txt:"
    grep -vE '^\s*#|^\s*$' "$repo_root/packages/aur.txt" | while IFS= read -r pkg; do
        pacman -Qq "$pkg" >/dev/null 2>&1 || echo "           $pkg"
    done
fi

if (( hyde_failed )); then
    echo
    echo "warning: HyDE's installer exited non-zero — some dotfiles may not have deployed."
    echo "         The overlay and theming steps above still ran. To retry just that part:"
    echo "           (cd vendor/hyde/Scripts && ./install.sh -r) && scripts/symlink-dotfiles.sh"
fi

if (( aur_failed || hyde_failed )); then
    exit 1
fi
