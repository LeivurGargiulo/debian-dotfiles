# Eww Animation Toolkit + Media Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a working eww popup for polybar's `nowplaying` module (art,
title, artist, album, live position, play/pause/prev/next) built on a
reusable eww animation toolkit, plus the build infrastructure needed to
install `eww` itself (no packaged binary exists) — and, since that
infrastructure is being added anyway, bring back two previously-skipped
build-from-source tools (`prism-tui`, `xwinwrap`) on top of it.

**Architecture:** `eww daemon` starts alongside polybar in
`chezmoi/dot_config/polybar/executable_launch.sh`. `mpris-daemon.sh`'s
existing `playerctl --follow` stream gains a second output: a JSON line
appended to `~/.cache/polybar/nowplaying.jsonl` per track/status change,
consumed by eww's `deflisten`. Polybar's own label (from the same stream)
is untouched. The popup is a persistent eww window (`wm-ignore true`, so
i3 never tiles it) whose body is wrapped in a `revealer` driven by a
`popup-visible` eww var — polybar's click handler toggles that var, giving
a real open/close animation instead of an instant window map/unmap. A
`defpoll` (`:run-while popup-visible`) ticks the live playback position
only while the popup is actually open. Colorice gets a new `eww-colors`
template so the popup follows the live Catppuccin palette, matching
polybar/i3/rofi. `eww` has no Debian package and no GitHub release binary
(source-only), so it's built via `cargo` — `prism-tui` needs a newer Rust
than apt ships, so a `rustup` stable toolchain is bootstrapped and used
for both. `xwinwrap` is a plain C/`make` build with no Rust involved.

**Tech Stack:** Ansible (Debian target), chezmoi, eww (yuck + SCSS),
playerctl, colorice, rustup/cargo, gcc/make.

**Spec:** `docs/superpowers/specs/2026-08-15-eww-animation-toolkit-media-widget-design.md`

## Global Constraints

- No packaged apt binary for `eww`; build via cargo/rustup — matches the
  precedent already recorded in `packages.yml` for skipping build-from-
  source tools, except this time we're building instead of skipping.
- `eww` build uses `--no-default-features --features x11` (this repo is
  X11/i3-only — no wayland, no `gtk-layer-shell` dependency needed).
- `prism-tui` requires Rust `>= 1.92.0`; apt's `rustc`/`cargo` is `1.85` —
  both `eww` and `prism-tui` build with a `rustup`-installed `stable`
  toolchain, not apt's rust packages.
- Built binaries install to `/usr/local/bin`, matching the existing
  `github_release_install.yml` convention (see
  `ansible/roles/packages/tasks/github_release_install.yml`).
- This is an infra/config repo with no application test suite. "Tests" in
  this plan are `ansible-playbook --syntax-check`, YAML/shell syntax
  checks, and `chezmoi diff` — run these at the end of every task instead
  of unit tests.
- Do not run a real (non-dry-run) `ansible-playbook site.yml` apply
  against the live machine as part of any task in this plan — that is an
  explicit, separate checkpoint with the user after all tasks are done
  (Task 9).
- Known simplification: the popup shows local (`file://`) album art only;
  remote (`https://`) art falls back to a generic icon — the old
  `now-playing-details.sh` fetched remote art via `curl` on click, but
  doing that inside the always-running `mpris-daemon.sh` stream loop would
  block it on every metadata change. Not extended in this plan.

---

### Task 1: Build-toolchain apt packages + rustup bootstrap

**Files:**
- Modify: `ansible/group_vars/all/packages.yml`
- Modify: `ansible/roles/dev-tools/tasks/main.yml`

**Interfaces:**
- Produces: `rustup`/`cargo`/`rustc` (stable channel) on `PATH` via
  `$HOME/.cargo/bin`, and the apt packages listed below — consumed by
  Task 2 (eww/prism-tui cargo builds) and Task 3 (xwinwrap C build).

- [ ] **Step 1: Add build-dependency apt packages**

In `ansible/group_vars/all/packages.yml`, find the `apt_packages:` list
(starts at line 2) and add these entries (grouped at the end of the
list, before the closing of `apt_packages`):

```yaml
  # eww build deps (crates/eww Cargo.toml + flake.nix buildInputs)
  - pkg-config
  - libgtk-3-dev
  - librsvg2-dev
  - libdbusmenu-gtk3-dev
  # xwinwrap build deps (per its README)
  - xorg-dev
  - libx11-dev
  - x11proto-xext-dev
  - libxrender-dev
  - libxext-dev
```

- [ ] **Step 2: Remove the now-outdated skip comment for prism-tui/xwinwrap**

In the same file, find the comment block listing skipped tools (around
line 85-97) and delete these two lines from it:

```yaml
  #   xwinwrap (dropped, build-from-source only, no packaged release)
  #   prism-tui (skipped, no packaged release, requires Rust 1.92+
  #   toolchain via rustup — apt's rustc/cargo is only 1.85)
```

- [ ] **Step 3: Add the `cargo_git_builds` var**

In `ansible/group_vars/all/packages.yml`, add a new top-level key (after
`github_release_binaries:`'s list ends, before `flatpak_apps:`):

```yaml
cargo_git_builds:
  - repo: elkowar/eww
    tag: v0.6.0
    binary_name: eww
    cargo_args: "-p eww --no-default-features --features x11"
  - repo: OneNoted/Prism-TUI
    tag: v0.3.0
    binary_name: prism-tui
    cargo_args: ""
```

- [ ] **Step 4: Bootstrap rustup in the `dev-tools` role**

In `ansible/roles/dev-tools/tasks/main.yml`, add this task before the
"Install pip user packages" task (at the top of the file):

```yaml
- name: Install rustup (stable toolchain — needed for eww/prism-tui; apt's rustc is too old for prism-tui)
  ansible.builtin.shell: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal
  args:
    creates: "{{ invoking_home }}/.cargo/bin/rustup"
  become: false
  environment:
    HOME: "{{ invoking_home }}"
```

- [ ] **Step 5: Verify YAML is well-formed**

Run: `python3 -c "import yaml; yaml.safe_load(open('ansible/group_vars/all/packages.yml'))"`
Expected: no output, exit code 0.

Run: `ansible-playbook ansible/site.yml --syntax-check`
Expected: `playbook: ansible/site.yml` printed, exit code 0.

- [ ] **Step 6: Commit**

```bash
git add ansible/group_vars/all/packages.yml ansible/roles/dev-tools/tasks/main.yml
git commit -m "Add eww/prism-tui/xwinwrap build deps and rustup bootstrap"
```

---

### Task 2: cargo git-build mechanism (eww + prism-tui)

**Files:**
- Create: `ansible/roles/packages/tasks/cargo_git_builds.yml`
- Modify: `ansible/roles/packages/tasks/main.yml`

**Interfaces:**
- Consumes: `cargo_git_builds` var (Task 1), `invoking_user`/
  `invoking_home` (defined in `ansible/site.yml:30-31`).
- Produces: `/usr/local/bin/eww`, `/usr/local/bin/prism-tui` — `eww`
  consumed by Task 6 onward (widgets), Task 8 (launch.sh).

- [ ] **Step 1: Write `cargo_git_builds.yml`**

Create `ansible/roles/packages/tasks/cargo_git_builds.yml`:

```yaml
---
- name: "Clone {{ item.repo }} at {{ item.tag }}"
  ansible.builtin.git:
    repo: "https://github.com/{{ item.repo }}.git"
    dest: "{{ invoking_home }}/.cache/source-builds/{{ item.binary_name }}"
    version: "{{ item.tag }}"
    force: true
  become: false
  become_user: "{{ invoking_user }}"
  environment:
    HOME: "{{ invoking_home }}"

- name: "Build {{ item.binary_name }} with cargo (release)"
  ansible.builtin.shell: |
    set -euo pipefail
    source "$HOME/.cargo/env"
    cargo build --release {{ item.cargo_args }}
  args:
    chdir: "{{ invoking_home }}/.cache/source-builds/{{ item.binary_name }}"
    executable: /bin/bash
    creates: "{{ invoking_home }}/.cache/source-builds/{{ item.binary_name }}/target/release/{{ item.binary_name }}"
  become: false
  become_user: "{{ invoking_user }}"
  environment:
    HOME: "{{ invoking_home }}"

- name: "Install {{ item.binary_name }} to /usr/local/bin"
  ansible.builtin.copy:
    src: "{{ invoking_home }}/.cache/source-builds/{{ item.binary_name }}/target/release/{{ item.binary_name }}"
    dest: "/usr/local/bin/{{ item.binary_name }}"
    mode: "0755"
    remote_src: true
  become: true
```

- [ ] **Step 2: Wire the loop into `main.yml`**

In `ansible/roles/packages/tasks/main.yml`, add after the "Install
non-apt binaries from GitHub releases" task:

```yaml
- name: Build and install cargo git binaries (eww, prism-tui)
  ansible.builtin.include_tasks: cargo_git_builds.yml
  loop: "{{ cargo_git_builds }}"
  loop_control:
    label: "{{ item.binary_name }}"
  tags: cargo_git_builds
```

- [ ] **Step 3: Verify syntax**

Run: `ansible-playbook ansible/site.yml --syntax-check`
Expected: exit code 0.

Run: `python3 -c "import yaml; yaml.safe_load(open('ansible/roles/packages/tasks/cargo_git_builds.yml'))"`
Expected: no output, exit code 0.

- [ ] **Step 4: Commit**

```bash
git add ansible/roles/packages/tasks/cargo_git_builds.yml ansible/roles/packages/tasks/main.yml
git commit -m "Add cargo git-build mechanism, wire up eww + prism-tui"
```

---

### Task 3: xwinwrap C build

**Files:**
- Create: `ansible/roles/packages/tasks/xwinwrap.yml`
- Modify: `ansible/roles/packages/tasks/main.yml`

**Interfaces:**
- Consumes: `invoking_user`/`invoking_home`, apt build deps from Task 1.
- Produces: `/usr/local/bin/xwinwrap`.

- [ ] **Step 1: Write `xwinwrap.yml`**

Create `ansible/roles/packages/tasks/xwinwrap.yml`:

```yaml
---
- name: Clone xwinwrap (r00tdaemon fork, pinned commit)
  ansible.builtin.git:
    repo: "https://github.com/r00tdaemon/xwinwrap.git"
    dest: "{{ invoking_home }}/.cache/source-builds/xwinwrap"
    version: "ec32e9b72539de7e1553a4f70345166107b431f7"
    force: true
  become: false
  become_user: "{{ invoking_user }}"
  environment:
    HOME: "{{ invoking_home }}"

- name: Build xwinwrap
  ansible.builtin.command: make
  args:
    chdir: "{{ invoking_home }}/.cache/source-builds/xwinwrap"
    creates: "{{ invoking_home }}/.cache/source-builds/xwinwrap/xwinwrap"
  become: false
  become_user: "{{ invoking_user }}"

- name: Install xwinwrap to /usr/local/bin
  ansible.builtin.command: make install
  args:
    chdir: "{{ invoking_home }}/.cache/source-builds/xwinwrap"
    creates: /usr/local/bin/xwinwrap
  become: true
```

- [ ] **Step 2: Wire it into `main.yml`**

In `ansible/roles/packages/tasks/main.yml`, add directly after the
"Build and install cargo git binaries" task from Task 2:

```yaml
- name: Build and install xwinwrap
  ansible.builtin.include_tasks: xwinwrap.yml
  tags: xwinwrap
```

- [ ] **Step 3: Verify syntax**

Run: `ansible-playbook ansible/site.yml --syntax-check`
Expected: exit code 0.

- [ ] **Step 4: Commit**

```bash
git add ansible/roles/packages/tasks/xwinwrap.yml ansible/roles/packages/tasks/main.yml
git commit -m "Build and install xwinwrap from source"
```

---

### Task 4: colorice eww template

**Files:**
- Create: `chezmoi/dot_config/colorice/templates/eww-colors.scss`
- Create: `ansible/roles/colorice/files/seed/eww-colorice-colors.scss`
- Modify: `chezmoi/dot_config/colorice/config.toml`
- Modify: `ansible/roles/colorice/tasks/main.yml`

**Interfaces:**
- Produces: `~/.config/eww/colorice-colors.scss` (via `colorice --apply`)
  with SCSS vars `$rosewater` through `$crust` — consumed by Task 6's
  `eww.scss`.

- [ ] **Step 1: Write the colorice template**

Create `chezmoi/dot_config/colorice/templates/eww-colors.scss`:

```scss
// colorice extended palette — generated from {wallpaper}
// Imported by eww.scss. Mirrors the same 26 Catppuccin roles used by
// polybar/i3/rofi's colorice templates, as SCSS variables.
$rosewater: {color1.lighten_30.desaturate_20};
$flamingo:  {color1.lighten_20.desaturate_15};
$pink:      {color5};
$mauve:     {color5.saturate_15};
$red:       {color1};
$maroon:    {color1.darken_10};
$peach:     {color3.darken_5.saturate_15};
$yellow:    {color3};
$green:     {color2};
$teal:      {color6};
$sky:       {color6.lighten_10};
$sapphire:  {color6.darken_5.saturate_10};
$blue:      {color4};
$lavender:  {color4.lighten_15.desaturate_10};
$text:      {foreground};
$subtext1:  {color7};
$subtext0:  {color15};
$overlay2:  {color7.darken_10};
$overlay1:  {color8.lighten_20};
$overlay0:  {color8.lighten_10};
$surface2:  {color8};
$surface1:  {color0};
$surface0:  {background.lighten_5};
$base:      {background};
$mantle:    {background.darken_5};
$crust:     {background.darken_10};
```

- [ ] **Step 2: Write the seed placeholder**

Create `ansible/roles/colorice/files/seed/eww-colorice-colors.scss` (same
Catppuccin Mocha Mauve hex values used by the other seed files):

```scss
// Placeholder — overwritten by `colorice <wallpaper> --apply`
$rosewater: #f5e0dc;
$flamingo:  #f2cdcd;
$pink:      #f5c2e7;
$mauve:     #cba6f7;
$red:       #f38ba8;
$maroon:    #eba0ac;
$peach:     #fab387;
$yellow:    #f9e2af;
$green:     #a6e3a1;
$teal:      #94e2d5;
$sky:       #89dceb;
$sapphire:  #74c7ec;
$blue:      #89b4fa;
$lavender:  #b4befe;
$text:      #cdd6f4;
$subtext1:  #bac2de;
$subtext0:  #a6adc8;
$overlay2:  #9399b2;
$overlay1:  #7f849c;
$overlay0:  #6c7086;
$surface2:  #585b70;
$surface1:  #45475a;
$surface0:  #313244;
$base:      #1e1e2e;
$mantle:    #181825;
$crust:     #11111b;
```

- [ ] **Step 3: Register the template in `config.toml`**

In `chezmoi/dot_config/colorice/config.toml`, add at the end of the
file:

```toml
[[templates]]
name = "eww-colors"
input = "eww-colors.scss"
output = "~/.config/eww/colorice-colors.scss"
hook = "eww reload"
```

- [ ] **Step 4: Add the seed-copy entry**

In `ansible/roles/colorice/tasks/main.yml`, add to the `loop:` list of
the "Seed placeholder colorice output files" task:

```yaml
    - { src: eww-colorice-colors.scss, dest: .config/eww/colorice-colors.scss }
```

- [ ] **Step 5: Verify syntax**

Run: `python3 -c "import tomllib; tomllib.load(open('chezmoi/dot_config/colorice/config.toml', 'rb'))"`
Expected: no output, exit code 0.

Run: `ansible-playbook ansible/site.yml --syntax-check`
Expected: exit code 0.

- [ ] **Step 6: Commit**

```bash
git add chezmoi/dot_config/colorice/templates/eww-colors.scss \
        ansible/roles/colorice/files/seed/eww-colorice-colors.scss \
        chezmoi/dot_config/colorice/config.toml \
        ansible/roles/colorice/tasks/main.yml
git commit -m "Add eww colorice template + seed placeholder"
```

---

### Task 5: mpris-daemon.sh JSON output

**Files:**
- Modify: `chezmoi/dot_config/polybar/scripts/executable_mpris-daemon.sh`

**Interfaces:**
- Produces: one JSON line per playback change appended to
  `~/.cache/polybar/nowplaying.jsonl`, shape
  `{"status": str, "title": str, "artist": str, "album": str, "art": str, "length": str}`
  (`art` is a local filesystem path or `""`) — consumed by Task 6's
  `deflisten`.
- Polybar's existing plain-text stdout line (unchanged) still feeds the
  `nowplaying` module's label.

- [ ] **Step 1: Rewrite the script**

Replace the full contents of
`chezmoi/dot_config/polybar/scripts/executable_mpris-daemon.sh`:

```bash
#!/bin/bash
# Event-driven mpris status for polybar (tail = true) and eww's
# nowplaying popup (tail -F on the jsonl log below). One playerctl
# --follow stream, two consumers.

CLEAR_DELAY=300
JSON_LOG="$HOME/.cache/polybar/nowplaying.jsonl"
mkdir -p "$(dirname "$JSON_LOG")"
_clear_pid=""

emit_json() {
    python3 - "$1" "$2" "$3" "$4" "$5" "$6" <<'PYEOF' >> "$JSON_LOG"
import json, sys
status, title, artist, album, art, length = sys.argv[1:7]
print(json.dumps({"status": status, "title": title, "artist": artist, "album": album, "art": art, "length": length}))
PYEOF
}

while IFS= read -r line; do
    status="${line%%|*}"
    title="${line#*|}"

    [ -n "$_clear_pid" ] && kill "$_clear_pid" 2>/dev/null
    _clear_pid=""

    artist=$(playerctl metadata artist 2>/dev/null)
    album=$(playerctl metadata album 2>/dev/null)
    art_url=$(playerctl metadata mpris:artUrl 2>/dev/null)
    length=$(playerctl metadata --format '{{duration(mpris:length)}}' 2>/dev/null)
    art_path=""
    [[ "$art_url" == file://* ]] && art_path="${art_url#file://}"
    emit_json "$status" "$title" "$artist" "$album" "$art_path" "$length"

    case "$status" in
        Playing)
            t="$title"
            [ "${#t}" -gt 40 ] && t="${t:0:40}…"
            echo "󰝚 $t"
            ;;
        Paused|Stopped)
            { sleep "$CLEAR_DELAY" && echo ""; } &
            _clear_pid=$!
            ;;
    esac
done < <(playerctl --follow metadata --format '{{status}}|{{title}}' 2>/dev/null)

echo ""
```

- [ ] **Step 2: Verify shell syntax**

Run: `bash -n chezmoi/dot_config/polybar/scripts/executable_mpris-daemon.sh`
Expected: no output, exit code 0.

- [ ] **Step 3: Manual smoke test of the JSON emitter**

Run:
```bash
bash -c '
CLEAR_DELAY=300
JSON_LOG=/tmp/nowplaying-test.jsonl
rm -f "$JSON_LOG"
source <(sed -n "/^emit_json/,/^}/p" chezmoi/dot_config/polybar/scripts/executable_mpris-daemon.sh)
emit_json "Playing" "Test Title" "Test Artist" "Test Album" "" "3:45"
cat "$JSON_LOG"
'
```
Expected: one line of valid JSON, e.g.
`{"status": "Playing", "title": "Test Title", "artist": "Test Artist", "album": "Test Album", "art": "", "length": "3:45"}`

- [ ] **Step 4: Commit**

```bash
git add chezmoi/dot_config/polybar/scripts/executable_mpris-daemon.sh
git commit -m "Emit JSON nowplaying stream alongside polybar's label"
```

---

### Task 6: eww daemon config — variables + window

**Files:**
- Create: `chezmoi/dot_config/eww/eww.yuck`
- Create: `chezmoi/dot_config/eww/eww.scss`
- Create: `chezmoi/dot_config/eww/animations.scss`

**Interfaces:**
- Consumes: `~/.cache/polybar/nowplaying.jsonl` (Task 5),
  `~/.config/eww/colorice-colors.scss` (Task 4, present via seed file
  even before first `colorice --apply`).
- Produces: `defvar popup-visible` (bool), `deflisten nowplaying_json`,
  `defwindow nowplaying-popup` — consumed by Task 7's widget and Task 8's
  polybar click handler.
- `$transition-fast`/`$transition-medium`/`$transition-slow`/`$ease` SCSS
  vars and `.eww-fade-hover` class in `animations.scss` — the shared
  animation toolkit, consumed by Task 7's widget SCSS and every later
  sub-project's widgets.

- [ ] **Step 1: Write `animations.scss`**

Create `chezmoi/dot_config/eww/animations.scss`:

```scss
// animations.scss — shared transition tokens. Import this in every eww
// widget's scss instead of hardcoding animation values, so every popup
// (media, volume, tray, sysinfo, notifications, calendar) stays visually
// consistent.

$transition-fast: 150ms;
$transition-medium: 250ms;
$transition-slow: 400ms;
$ease: cubic-bezier(0.4, 0, 0.2, 1);

.eww-fade-hover {
  transition: opacity $transition-fast $ease;
}
.eww-fade-hover:hover {
  opacity: 0.8;
}
```

- [ ] **Step 2: Write `eww.yuck`**

Create `chezmoi/dot_config/eww/eww.yuck`:

```lisp
;; eww.yuck — daemon-level config: shared state + window definitions.
;; Widget bodies live in widgets/*.yuck.

(include "./widgets/nowplaying.yuck")

;; Drives the nowplaying-popup's revealer. The window itself stays open
;; permanently (opened once from launch.sh); this var is what polybar's
;; click handler toggles to animate it in/out.
(defvar popup-visible false)

;; One JSON line per playback change, appended by mpris-daemon.sh.
;; Falls back to an empty object so widget field lookups don't error out
;; before the first line is written.
(deflisten nowplaying_json :initial "{}"
  `tail -F -n1 $HOME/.cache/polybar/nowplaying.jsonl`)

;; Live playback position — polled only while the popup is visible, so it
;; doesn't run a playerctl call every second in the background.
(defpoll nowplaying_position :interval "1s"
                              :initial ""
                              :run-while popup-visible
  `playerctl position --format "{{ duration(position) }}" 2>/dev/null`)

(defwindow nowplaying-popup
  :monitor 0
  :geometry (geometry :x "0px"
                       :y "29px"
                       :width "320px"
                       :height "140px"
                       :anchor "bottom center")
  :stacking "fg"
  :wm-ignore true
  (nowplaying :json nowplaying_json
              :position nowplaying_position
              :visible popup-visible))
```

- [ ] **Step 3: Write `eww.scss`**

Create `chezmoi/dot_config/eww/eww.scss`:

```scss
@import "colorice-colors.scss";
@import "animations.scss";
@import "widgets/nowplaying.scss";

* {
  font-family: "CaskaydiaCove Nerd Font", sans-serif;
}
```

- [ ] **Step 4: Verify yuck/scss parse (requires `eww` binary from Task 2)**

Run: `eww --config chezmoi/dot_config/eww validate`
Expected: exits 0 (widgets/nowplaying.yuck doesn't exist yet, this step
will fail until Task 7 — if `eww` isn't built yet, or Task 7 isn't done
yet, skip this check for now and re-run it at the end of Task 7 instead).

- [ ] **Step 5: Commit**

```bash
git add chezmoi/dot_config/eww/eww.yuck chezmoi/dot_config/eww/eww.scss chezmoi/dot_config/eww/animations.scss
git commit -m "Add eww daemon config: nowplaying state + window + animation toolkit"
```

---

### Task 7: nowplaying widget

**Files:**
- Create: `chezmoi/dot_config/eww/widgets/nowplaying.yuck`
- Create: `chezmoi/dot_config/eww/widgets/nowplaying.scss`

**Interfaces:**
- Consumes: `:json` (JSON string, fields `status`/`title`/`artist`/
  `album`/`art`/`length`), `:position` (string), `:visible` (bool) —
  attribute names must match Task 6's `(nowplaying :json ... :position
  ... :visible ...)` call exactly.
- Consumes SCSS vars from Task 6's `animations.scss`
  (`.eww-fade-hover`) and Task 4's `colorice-colors.scss` (`$base`,
  `$text`, `$subtext0`, `$overlay1`, `$surface0`, `$mauve`).

- [ ] **Step 1: Write `nowplaying.yuck`**

Create `chezmoi/dot_config/eww/widgets/nowplaying.yuck`:

```lisp
(defwidget nowplaying [json position visible]
  (revealer :transition "slideup"
            :duration "250ms"
            :reveal visible
    (box :class "nowplaying-popup"
         :orientation "vertical"
         :space-evenly false
      (box :class "nowplaying-header"
           :orientation "horizontal"
           :space-evenly false
        (image :class "nowplaying-art"
               :path {json.art != "" ? json.art : "/usr/share/icons/Papirus-Dark/64x64/mimetypes/audio-x-generic.svg"}
               :image-width 64
               :image-height 64)
        (box :class "nowplaying-meta"
             :orientation "vertical"
             :space-evenly false
          (label :class "nowplaying-title" :text "${json.title}" :limit-width 28 :wrap true)
          (label :class "nowplaying-artist" :text "${json.artist}" :limit-width 28)
          (label :class "nowplaying-album" :text "${json.album}" :limit-width 28)))
      (box :class "nowplaying-controls"
           :orientation "horizontal"
           :halign "center"
           :space-evenly true
        (button :class "nowplaying-btn eww-fade-hover" :onclick "playerctl previous" "󰒮")
        (button :class "nowplaying-btn eww-fade-hover" :onclick "playerctl play-pause" {json.status == "Playing" ? "󰏤" : "󰐊"})
        (button :class "nowplaying-btn eww-fade-hover" :onclick "playerctl next" "󰒭"))
      (label :class "nowplaying-position" :text "${position} / ${json.length}"))))
```

- [ ] **Step 2: Write `nowplaying.scss`**

Create `chezmoi/dot_config/eww/widgets/nowplaying.scss`:

```scss
.nowplaying-popup {
  background-color: $base;
  color: $text;
  border-radius: 8px;
  padding: 8px;
}

.nowplaying-art {
  border-radius: 4px;
}

.nowplaying-meta {
  margin-left: 8px;
}

.nowplaying-title {
  font-weight: bold;
  color: $text;
}

.nowplaying-artist, .nowplaying-album {
  color: $subtext0;
  font-size: 0.85em;
}

.nowplaying-btn {
  background-color: $surface0;
  color: $mauve;
  border-radius: 6px;
  padding: 4px 10px;
  margin: 4px;
}

.nowplaying-position {
  color: $overlay1;
  font-size: 0.8em;
  margin-top: 4px;
}
```

- [ ] **Step 3: Validate the full eww config**

Run: `eww --config chezmoi/dot_config/eww validate`
Expected: exit code 0, no yuck/scss errors printed. (Requires `eww` from
Task 2 and colorice-colors.scss present — the seed file from Task 4
covers this on a fresh machine; on this dev machine, symlink or copy
`ansible/roles/colorice/files/seed/eww-colorice-colors.scss` to
`~/.config/eww/colorice-colors.scss` first if it doesn't exist yet.)

- [ ] **Step 4: Commit**

```bash
git add chezmoi/dot_config/eww/widgets/nowplaying.yuck chezmoi/dot_config/eww/widgets/nowplaying.scss
git commit -m "Add nowplaying widget"
```

---

### Task 8: Wire polybar + launch.sh to eww

**Files:**
- Modify: `chezmoi/dot_config/polybar/executable_launch.sh`
- Modify: `chezmoi/dot_config/polybar/config.ini`
- Delete: `chezmoi/dot_config/polybar/scripts/executable_now-playing-details.sh`

**Interfaces:**
- Consumes: `eww` binary (Task 2), `nowplaying-popup` window + `popup-
  visible` var (Task 6).

- [ ] **Step 1: Update `launch.sh`**

Replace the full contents of
`chezmoi/dot_config/polybar/executable_launch.sh`:

```bash
#!/usr/bin/env bash

killall -q polybar
pkill -f mpris-daemon.sh
eww kill 2>/dev/null

while pgrep -x polybar >/dev/null; do sleep 1; done

eww daemon
# ponytail: fixed 0.5s wait for the daemon socket, no retry loop — fine
# for a login-time launch script, revisit if `eww open` below ever races.
sleep 0.5
eww open nowplaying-popup

polybar main &
```

- [ ] **Step 2: Update the `nowplaying` module's click handler**

In `chezmoi/dot_config/polybar/config.ini`, in the `[module/nowplaying]`
section (currently lines 118-128), replace:

```ini
click-left = ~/.config/polybar/scripts/now-playing-details.sh
```

with:

```ini
click-left = eww update popup-visible=$([ "$(eww get popup-visible)" = "true" ] && echo false || echo true)
```

- [ ] **Step 3: Delete the superseded script**

```bash
rm chezmoi/dot_config/polybar/scripts/executable_now-playing-details.sh
```

- [ ] **Step 4: Verify shell syntax**

Run: `bash -n chezmoi/dot_config/polybar/executable_launch.sh`
Expected: no output, exit code 0.

- [ ] **Step 5: Verify polybar config still parses**

Run: `polybar --config=chezmoi/dot_config/polybar/config.ini -m 2>&1 | head -5`
Expected: no `error while parsing` output (module list, not a crash — a
"no monitors" message from a headless/dry environment is fine).

- [ ] **Step 6: Commit**

```bash
git add chezmoi/dot_config/polybar/executable_launch.sh chezmoi/dot_config/polybar/config.ini
git rm chezmoi/dot_config/polybar/scripts/executable_now-playing-details.sh
git commit -m "Wire eww daemon + nowplaying popup into polybar launch/click"
```

---

### Task 9: Full-repo verification checkpoint

**Files:** none (verification only).

**Interfaces:** none.

- [ ] **Step 1: Ansible syntax check**

Run: `ansible-playbook ansible/site.yml --syntax-check`
Expected: exit code 0.

- [ ] **Step 2: chezmoi dry-run diff**

Run: `chezmoi diff --source chezmoi 2>&1 | head -100`
Expected: diff shows the new/changed files from Tasks 4-8 (eww/*,
colorice config.toml + templates, polybar launch.sh/config.ini/scripts),
no errors.

- [ ] **Step 3: Full eww config validation**

Run: `eww --config chezmoi/dot_config/eww validate`
Expected: exit code 0.

- [ ] **Step 4: Report to user, do not apply live**

Tell the user: all syntax/dry-run checks pass; a real
`ansible-playbook site.yml --ask-become-pass` run (or `chezmoi apply` +
manual `eww daemon`/`polybar` restart) is needed to actually build eww/
prism-tui/xwinwrap and see the popup live — that run is the user's call,
not part of this plan.
