# arch-dotfiles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a git-tracked dotfiles repo for CachyOS + Hyprland (AMD GPU) that forks HyDE as its rice base, with an idempotent `install.sh` so a reformat is "clone repo, run script."

**Architecture:** HyDE is vendored unmodified as a git subtree at `vendor/hyde/`. All customization lives in a `dotfiles/` overlay (mirrors `$HOME` layout) applied by a small symlink script that runs after HyDE's own installer. Two plain-text package lists (`packages/pacman.txt`, `packages/aur.txt`) drive `pacman -S --needed -` / `yay -S --needed -`; `--needed` is what makes re-running safe, no extra tooling layer (no Ansible, no chezmoi).

**Tech Stack:** bash, git (subtree), pacman/yay, gh CLI (already authenticated as `LeivurGargiulo` this session).

**Spec:** `docs/superpowers/specs/2026-08-16-arch-dotfiles-design.md`

## Global Constraints

- No Ansible, no chezmoi/stow — plain package lists + a symlink script.
- `vendor/hyde/` is never hand-edited; all customization lives in `dotfiles/`.
- Every script must be safe to re-run end to end (idempotent, no destructive ops).
- No live test of `install.sh` against a real CachyOS machine this pass (none available) — verify via `bash -n`, `shellcheck`, and structural tests instead.
- `packages/pacman.txt` / `packages/aur.txt` allow `#`-comment lines and blank lines for human readability; anything that consumes them must strip those before piping to pacman/yay.

---

### Task 1: Fork and vendor HyDE

**Files:**
- Create: `vendor/hyde/` (git subtree content, not hand-written)

**Interfaces:**
- Produces: `vendor/hyde/Scripts/install.sh` (HyDE's own installer, consumed by Task 5's `install.sh`)

- [ ] **Step 1: Fork HyDE-Project/HyDE to the authenticated GitHub account**

```bash
gh repo fork HyDE-Project/HyDE --clone=false
```

Expected: prints a URL like `https://github.com/LeivurGargiulo/HyDE` (or reports it already exists — either is fine, idempotent).

- [ ] **Step 2: Add the fork as a git subtree at `vendor/hyde`**

```bash
git subtree add --prefix vendor/hyde git@github.com:LeivurGargiulo/HyDE.git master --squash
```

Expected: a new commit is created (subtree merge commit); `vendor/hyde/Scripts/install.sh` exists.

- [ ] **Step 3: Verify the vendored installer is present**

```bash
test -f vendor/hyde/Scripts/install.sh && echo OK
```

Expected: `OK`

- [ ] **Step 4: Commit (the subtree add already committed in Step 2 — this step is a no-op if `git status` is clean)**

```bash
git status --short
```

Expected: empty (subtree add already committed). If not empty, investigate before proceeding — do not force-add unrelated changes.

---

### Task 2: Package lists

**Files:**
- Create: `packages/pacman.txt`
- Create: `packages/aur.txt`

**Interfaces:**
- Produces: two newline-delimited package-name files (with optional `#` comments and blank lines) consumed by `install.sh` (Task 5) via `grep -vE '^\s*#|^\s*$'`.

- [ ] **Step 1: Write `packages/pacman.txt`**

```
# --- AMD Wayland GPU stack ---
mesa
vulkan-radeon
vulkan-icd-loader
libva-mesa-driver
mesa-vdpau

# --- core CLI ---
curl
eza
bat
fd
ripgrep
fzf
zoxide
tmux
mosh
jq
git
zsh
p7zip
unrar
ffmpeg
python
python-pip
jdk-openjdk
openssh
docker
docker-compose
unzip
imagemagick
git-delta
duf
smartmontools
hdparm
ncdu
btop
chafa
lftp
rclone
wl-clipboard
playerctl
udiskie
newsboat
cmus
oath-toolkit
taskwarrior
calcurse
yt-dlp
atuin
lazygit
yazi

# --- TUI-first picks ---
zathura
zathura-pdf-mupdf
mpv
rtorrent
cava

# --- firewall / disk ---
ufw
gparted

# --- GUI apps, no TUI equivalent ---
remmina
gimp
kdenlive
obs-studio
libnotify

# --- gaming (multilib) ---
steam

# --- flatpak runtime, apps installed separately (see README) ---
flatpak

# --- shell environment ---
zsh-autosuggestions
zsh-syntax-highlighting
zsh-completions
zsh-history-substring-search
starship

# --- misc, now packaged in official repos ---
tailscale
uv
rustup
```

- [ ] **Step 2: Write `packages/aur.txt`**

```
# --- AMD GPU monitor ---
amdgpu_top

# --- CLI/TUI tools without an official-repo package ---
ncspot
bandwhich
bluetuith
glow
ducker
taskwarrior-tui
gophertube
wden
pulsemixer
ytfzf
nvm

# --- password / 2FA ---
rbw
rofi-rbw

# --- browsers / chat (AUR -bin builds) ---
zen-browser-bin
rustdesk-bin
vesktop-bin
zapzap-bin
```

- [ ] **Step 3: Verify both files are non-empty and comment-stripping works as `install.sh` will use it**

```bash
grep -vE '^\s*#|^\s*$' packages/pacman.txt | wc -l
grep -vE '^\s*#|^\s*$' packages/aur.txt | wc -l
```

Expected: two positive counts (pacman.txt: 60+ lines, aur.txt: 18 lines).

- [ ] **Step 4: Commit**

```bash
git add packages/pacman.txt packages/aur.txt
git commit -m "packages: hand-curated pacman/AUR lists ported from debian-dotfiles"
```

---

### Task 3: `scripts/regenerate-packages.sh`

**Files:**
- Create: `scripts/regenerate-packages.sh`
- Test: `scripts/tests/test_regenerate-packages.sh`

**Interfaces:**
- Consumes: `pacman -Qqe`, `pacman -Qqm` (stubbed in the test via a fake `pacman` on `PATH`)
- Produces: overwrites `packages/pacman.txt` and `packages/aur.txt` (same file paths as Task 2)

- [ ] **Step 1: Write the test first**

```bash
#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Fake repo layout
mkdir -p "$tmp/repo/scripts" "$tmp/repo/packages"
script_under_test="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/regenerate-packages.sh"
cp "$script_under_test" "$tmp/repo/scripts/regenerate-packages.sh"
chmod +x "$tmp/repo/scripts/regenerate-packages.sh"

# Fake pacman on PATH
mkdir -p "$tmp/bin"
cat > "$tmp/bin/pacman" <<'FAKE'
#!/usr/bin/env bash
if [[ "$1" == "-Qqe" ]]; then
    printf 'btop\nyay-bin\nzsh\n'
elif [[ "$1" == "-Qqm" ]]; then
    printf 'yay-bin\n'
fi
FAKE
chmod +x "$tmp/bin/pacman"

PATH="$tmp/bin:$PATH" "$tmp/repo/scripts/regenerate-packages.sh"

pacman_out="$(cat "$tmp/repo/packages/pacman.txt")"
aur_out="$(cat "$tmp/repo/packages/aur.txt")"

expected_pacman=$'btop\nzsh'
expected_aur='yay-bin'

if [[ "$pacman_out" != "$expected_pacman" ]]; then
    echo "FAIL: pacman.txt = '$pacman_out', expected '$expected_pacman'" >&2
    exit 1
fi
if [[ "$aur_out" != "$expected_aur" ]]; then
    echo "FAIL: aur.txt = '$aur_out', expected '$expected_aur'" >&2
    exit 1
fi

echo "PASS"
```

- [ ] **Step 2: Run the test to verify it fails (script doesn't exist yet)**

```bash
mkdir -p scripts/tests
chmod +x scripts/tests/test_regenerate-packages.sh 2>/dev/null || true
bash scripts/tests/test_regenerate-packages.sh
```

Expected: FAIL (`No such file or directory` for `regenerate-packages.sh`, since Step 1 only wrote the test — the file `scripts/regenerate-packages.sh` doesn't exist until Step 3).

- [ ] **Step 3: Write `scripts/regenerate-packages.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pacman -Qqm | sort > "$repo_root/packages/aur.txt"
comm -23 <(pacman -Qqe | sort) <(pacman -Qqm | sort) > "$repo_root/packages/pacman.txt"

echo "regenerated packages/pacman.txt and packages/aur.txt from the live system"
echo "review the diff (category # comments from the hand-curated version are gone), then commit"
```

- [ ] **Step 4: Make it executable and run the test again**

```bash
chmod +x scripts/regenerate-packages.sh
bash scripts/tests/test_regenerate-packages.sh
```

Expected: `PASS`

- [ ] **Step 5: Run shellcheck**

```bash
shellcheck scripts/regenerate-packages.sh scripts/tests/test_regenerate-packages.sh
```

Expected: no warnings/errors (or only informational, resolve anything real).

- [ ] **Step 6: Commit**

```bash
git add scripts/regenerate-packages.sh scripts/tests/test_regenerate-packages.sh
git commit -m "scripts: add regenerate-packages.sh with test"
```

---

### Task 4: Dotfiles overlay + symlink script

**Files:**
- Create: `dotfiles/.config/hypr/monitors.conf`
- Create: `scripts/symlink-dotfiles.sh`
- Test: `scripts/tests/test_symlink-dotfiles.sh`

**Interfaces:**
- Consumes: nothing from prior tasks
- Produces: `scripts/symlink-dotfiles.sh` (a function of `$HOME`, callable with `HOME` overridden for testing — consumed by `install.sh` in Task 5)

- [ ] **Step 1: Write the monitor placeholder**

```
# TODO: real hardware — fill in with actual `hyprctl monitors` output
# once this repo is applied on the real 3x 1080p desktop.
#
# Example only — DO NOT use these output names as-is, they are
# placeholders (real names come from `hyprctl monitors`):
#
# monitor=DP-1,1920x1080@60,0x0,1
# monitor=DP-2,1920x1080@60,1920x0,1
# monitor=HDMI-A-1,1920x1080@60,3840x0,1
```

Write this to `dotfiles/.config/hypr/monitors.conf`.

- [ ] **Step 2: Write the test for the symlink script first**

```bash
#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/repo/scripts" "$tmp/repo/dotfiles/.config/hypr"
echo "placeholder" > "$tmp/repo/dotfiles/.config/hypr/monitors.conf"

script_under_test="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/symlink-dotfiles.sh"
cp "$script_under_test" "$tmp/repo/scripts/symlink-dotfiles.sh"
chmod +x "$tmp/repo/scripts/symlink-dotfiles.sh"

fake_home="$tmp/home"
mkdir -p "$fake_home"
HOME="$fake_home" "$tmp/repo/scripts/symlink-dotfiles.sh"

link="$fake_home/.config/hypr/monitors.conf"
if [[ ! -L "$link" ]]; then
    echo "FAIL: $link is not a symlink" >&2
    exit 1
fi
target="$(readlink -f "$link")"
expected="$tmp/repo/dotfiles/.config/hypr/monitors.conf"
if [[ "$target" != "$(readlink -f "$expected")" ]]; then
    echo "FAIL: symlink target = $target, expected $expected" >&2
    exit 1
fi

# Re-run to confirm idempotency (no error, still a valid symlink)
HOME="$fake_home" "$tmp/repo/scripts/symlink-dotfiles.sh"
[[ -L "$link" ]] || { echo "FAIL: not idempotent"; exit 1; }

echo "PASS"
```

Save as `scripts/tests/test_symlink-dotfiles.sh`.

- [ ] **Step 3: Run the test to verify it fails**

```bash
chmod +x scripts/tests/test_symlink-dotfiles.sh
bash scripts/tests/test_symlink-dotfiles.sh
```

Expected: FAIL (`scripts/symlink-dotfiles.sh` doesn't exist yet).

- [ ] **Step 4: Write `scripts/symlink-dotfiles.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src_root="$repo_root/dotfiles"

find "$src_root" -type f | while IFS= read -r src; do
    rel="${src#"$src_root"/}"
    dest="$HOME/$rel"
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
    echo "linked: ~/$rel"
done
```

- [ ] **Step 5: Make it executable and run the test again**

```bash
chmod +x scripts/symlink-dotfiles.sh
bash scripts/tests/test_symlink-dotfiles.sh
```

Expected: `PASS`

- [ ] **Step 6: Run shellcheck**

```bash
shellcheck scripts/symlink-dotfiles.sh scripts/tests/test_symlink-dotfiles.sh
```

Expected: no real warnings/errors.

- [ ] **Step 7: Commit**

```bash
git add dotfiles/.config/hypr/monitors.conf scripts/symlink-dotfiles.sh scripts/tests/test_symlink-dotfiles.sh
git commit -m "dotfiles: add monitors.conf placeholder and symlink-dotfiles.sh with test"
```

---

### Task 5: `install.sh`

**Files:**
- Create: `install.sh`
- Test: `scripts/tests/test_install-sh-structure.sh`

**Interfaces:**
- Consumes: `packages/pacman.txt`, `packages/aur.txt` (Task 2), `vendor/hyde/Scripts/install.sh` (Task 1), `scripts/symlink-dotfiles.sh` (Task 4)
- Produces: nothing consumed by later tasks (top-level entrypoint)

- [ ] **Step 1: Write the structural test first**

Full live execution needs pacman/yay/root/network/HyDE's installer, none available this session (per spec, out of scope this pass). This test instead verifies `install.sh` is syntactically valid and references every file it depends on, so a broken path reference is caught now instead of on real hardware.

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$repo_root/install.sh"
echo "syntax OK"

for f in packages/pacman.txt packages/aur.txt vendor/hyde/Scripts/install.sh scripts/symlink-dotfiles.sh; do
    if [[ ! -f "$repo_root/$f" ]]; then
        echo "FAIL: install.sh depends on missing file: $f" >&2
        exit 1
    fi
    if ! grep -q "$f" "$repo_root/install.sh" && ! grep -q "$(basename "$f")" "$repo_root/install.sh"; then
        echo "FAIL: install.sh never references $f" >&2
        exit 1
    fi
done

echo "PASS"
```

Save as `scripts/tests/test_install-sh-structure.sh`.

- [ ] **Step 2: Run the test to verify it fails**

```bash
chmod +x scripts/tests/test_install-sh-structure.sh
bash scripts/tests/test_install-sh-structure.sh
```

Expected: FAIL (`install.sh` doesn't exist yet — `bash -n` errors on missing file).

- [ ] **Step 3: Write `install.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

echo "==> running vendor/hyde/Scripts/install.sh (HyDE's own installer)"
(cd "$repo_root/vendor/hyde/Scripts" && ./install.sh)

echo "==> applying dotfiles overlay (scripts/symlink-dotfiles.sh)"
"$repo_root/scripts/symlink-dotfiles.sh"

cat <<'EOF'

==> done.

Reminder: dotfiles/.config/hypr/monitors.conf is a placeholder.
Once on real hardware, run `hyprctl monitors`, fill in real output
names/positions in that file, then re-run:
  scripts/symlink-dotfiles.sh
(or re-run install.sh — it's safe to re-run end to end)
EOF
```

- [ ] **Step 4: Make it executable and run the test again**

```bash
chmod +x install.sh
bash scripts/tests/test_install-sh-structure.sh
```

Expected: `PASS`

- [ ] **Step 5: Run shellcheck**

```bash
shellcheck install.sh scripts/tests/test_install-sh-structure.sh
```

Expected: no real warnings/errors.

- [ ] **Step 6: Commit**

```bash
git add install.sh scripts/tests/test_install-sh-structure.sh
git commit -m "install: add top-level idempotent install.sh with structural test"
```

---

### Task 6: README

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: nothing (documentation only)

- [ ] **Step 1: Write `README.md`**

```markdown
# arch-dotfiles

CachyOS + Hyprland dotfiles, AMD GPU, forked from
[HyDE](https://github.com/HyDE-Project/HyDE) as the rice base. No
Ansible, no chezmoi — a symlink overlay plus `pacman -S --needed` /
`yay -S --needed` package lists, which gives idempotency without an
extra tooling layer. Goal: reformat = clone this repo, run
`install.sh`.

## What's HyDE vs what's ours

- `vendor/hyde/` — HyDE, vendored as a git subtree from
  [LeivurGargiulo/HyDE](https://github.com/LeivurGargiulo/HyDE) (a
  fork of `HyDE-Project/HyDE`). **Never hand-edited.** Provides
  Hyprland, Waybar, rofi, a lock screen, a notification daemon, GTK/Qt
  theming, and its own package/install logic.
- `dotfiles/` — our overlay, mirrors `$HOME` layout exactly (e.g.
  `dotfiles/.config/hypr/monitors.conf` → `~/.config/hypr/monitors.conf`).
  Applied last, after HyDE's installer, so it always wins.
- `packages/pacman.txt` / `packages/aur.txt` — everything beyond what
  HyDE's own installer already pulls in: the AMD driver stack and the
  CLI/TUI tools ported from a previous (Debian) dotfiles setup.
- `install.sh`, `scripts/` — glue: package install, run HyDE's
  installer, apply the overlay.

## CachyOS vs vanilla Arch

CachyOS is Arch-based with its own performance-tuned repos/kernel;
HyDE's installer targets "Arch or Arch-based" and works as-is. No
CachyOS-specific package renames are known yet — if `install.sh` hits
one (a package under a different name in CachyOS's repos), fix it in
`packages/pacman.txt`/`packages/aur.txt` directly and note it here.

## Fresh install

```sh
git clone <this-repo-url> ~/arch-dotfiles
cd ~/arch-dotfiles
./install.sh
```

Safe to re-run end to end — every step uses `--needed`/`-sfn`-style
idempotent operations.

**3-monitor setup:** `dotfiles/.config/hypr/monitors.conf` ships as a
placeholder. After first install, run `hyprctl monitors`, fill in the
real output names/positions, then re-run `scripts/symlink-dotfiles.sh`
(or all of `install.sh`).

## Updating HyDE

```sh
git subtree pull --prefix vendor/hyde git@github.com:LeivurGargiulo/HyDE.git master --squash
```

If the fork itself is behind `HyDE-Project/HyDE`, sync it first (GitHub
web UI "Sync fork," or `gh repo sync LeivurGargiulo/HyDE`), then run
the `subtree pull` above.

## Regenerating package lists

After installing anything new by hand:

```sh
./scripts/regenerate-packages.sh
git diff packages/
git add packages/ && git commit -m "packages: regenerate from live system"
```

This overwrites both files from the live system's `pacman -Qqe`/`-Qqm`
— it drops the hand-written `#` category comments from the original
curated lists. Re-add comments by hand if you want them back, or just
let the plain list stand.

## Not automated yet

These were part of the prior (Debian) setup and aren't wired into
`install.sh` — install manually for now, promote into the automated
flow later if it's worth it:

- pip user packages (`beautifulsoup4`, `pandas`, `pytest`, etc. — see
  `../debian-dotfiles/docs/SOFTWARE_LIST.md` for the full list)
- npm globals (`@anthropic-ai/claude-code`, `@bitwarden/cli`)
- `oh-my-zsh` + its custom plugins, `nvm`-installed Node LTS, `tmux`
  plugin manager (tpm) — shell-environment setup scripts, not packages
- Cargo-only tools (e.g. Raijin weather TUI, no pre-built binary)
- Flatpak apps (Zen Browser, RustDesk, Vesktop, Telegram, ZapZap,
  EasyEffects, GNOME Boxes, PrismLauncher, input-leap) — `flatpak` itself
  is in `packages/pacman.txt`; install apps with `flatpak install
  flathub <app-id>` once needed
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README"
```

---

### Task 7: Final review pass

**Files:**
- Modify: any file touched above, if issues are found

**Interfaces:**
- Consumes: everything from Tasks 1–6

- [ ] **Step 1: Run every test**

```bash
for t in scripts/tests/test_*.sh; do
    echo "=== $t ==="
    bash "$t"
done
```

Expected: `PASS` for every test.

- [ ] **Step 2: Run shellcheck on every script**

```bash
shellcheck install.sh scripts/*.sh scripts/tests/*.sh
```

Expected: no real warnings/errors. Fix anything real, re-run.

- [ ] **Step 3: Confirm no placeholders slipped through**

```bash
grep -rn "TBD\|FIXME" --include='*.sh' --include='*.md' . | grep -v '\.git/'
```

Expected: no matches, OR only the intentional `# TODO: real hardware`
marker in `dotfiles/.config/hypr/monitors.conf` (that one is
deliberate per the spec, not a plan gap).

- [ ] **Step 4: Verify repo structure matches the spec**

```bash
git ls-files | sort
```

Expected: includes `install.sh`, `README.md`, `packages/pacman.txt`,
`packages/aur.txt`, `scripts/regenerate-packages.sh`,
`scripts/symlink-dotfiles.sh`, `scripts/tests/test_*.sh`,
`dotfiles/.config/hypr/monitors.conf`, plus everything under
`vendor/hyde/` from the subtree add.

- [ ] **Step 5: Final commit if Step 2/3 required fixes**

```bash
git add -A
git commit -m "chore: fix shellcheck/placeholder findings from final review"
```

(Skip this step if nothing changed.)
