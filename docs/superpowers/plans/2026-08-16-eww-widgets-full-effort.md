# Eww Widgets + Animation Toolkit — Full 7-Sub-Project Effort Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate the entire "eww widgets + transitions/animations library for
polybar" effort into one status-tracked document: sub-projects 1 (media popup)
and 2 (volume popup) are implemented and merged, sub-project 3 (sysinfo
drawer) is fully spec'd and planned but not yet implemented — its tasks are
reproduced here verbatim from `docs/superpowers/plans/2026-08-16-eww-sysinfo-drawer.md`
so this doc is a complete, self-contained checklist — and sub-projects 4–7
(tray/powermenu, notification center, calendar, and one open future slot)
have no spec yet and are explicitly out of scope for execution until they go
through `superpowers:brainstorming` first.

**Architecture:** Every sub-project follows the same pattern established in
sub-project 1: polybar keeps a slim icon/label module; clicking it toggles a
persistent `wm-ignore true` eww window wrapped in a `revealer` for open/close
animation, themed via the shared `colorice` palette and the shared
`animations.scss` toolkit. Sub-project 3 deviates once (confirmed with repo
owner): it replaces four existing polybar modules instead of augmenting them.

**Tech Stack:** eww (yuck + SCSS), polybar, `playerctl`/`pactl`/`/proc`/`free`/
`amdgpu_top`, bash, python3 (JSON emission), colorice (Catppuccin palette
generation), ansible (chezmoi source lives under `ansible`-managed dotfiles).

**Spec:** `docs/superpowers/specs/2026-08-15-eww-animation-toolkit-media-widget-design.md`
(master 7-part decomposition + sub-project 1 spec),
`docs/superpowers/specs/2026-08-15-eww-volume-popup-design.md` (sub-project 2),
`docs/superpowers/specs/2026-08-16-eww-sysinfo-drawer-design.md` (sub-project 3).
Sub-projects 4–7 have no spec — see "Sub-projects 4–7" section below.

## Global Constraints

- No new colorice template beyond the one sub-project 1 added
  (`chezmoi/dot_config/colorice/templates/eww-colors.scss`) — sub-projects 2
  and 3 reuse it as-is.
- Every popup window is a persistent `:wm-ignore true` `defwindow`, opened
  once at `eww daemon` startup in `executable_launch.sh` and never closed —
  visibility is controlled purely by the `revealer` inside, driven by a
  `defvar *-popup-visible` that polybar's `click-left` toggles.
- No new persistent background daemon per widget beyond what already exists
  (`mpris-daemon.sh` for nowplaying). Sub-project 2's volume status and
  sub-project 3's sysinfo status are one-shot scripts polled via `defpoll
  :run-while <popup>-visible` — only while their popup is open.
- This is an infra/config repo with no application test suite. "Tests" are
  `bash -n`, standalone script smoke tests, `ansible-playbook --syntax-check`,
  and manual yuck/scss paren/brace balance checks.
- No `eww`/`polybar` binaries are available in the dev sandbox this plan is
  likely executed in — `eww validate` / live polybar checks are best-effort,
  not blockers, deferred to a provisioned machine.
- Do not run a real (non-dry-run) `ansible-playbook site.yml` apply or a live
  `eww`/`polybar` restart against a real machine as part of any task in this
  plan.

---

## Sub-project 1: Animation toolkit + media popup — DONE (merged)

No tasks here — already implemented and merged to `main`. Reference only.

**Files delivered:**
- `chezmoi/dot_config/eww/animations.scss` — shared transition toolkit,
  imported by every later widget's `.scss`.
- `chezmoi/dot_config/eww/eww.yuck`, `eww.scss` — daemon config,
  `nowplaying-popup` window.
- `chezmoi/dot_config/eww/widgets/nowplaying.yuck` / `.scss` — the widget.
- `chezmoi/dot_config/polybar/scripts/executable_mpris-daemon.sh` — emits
  JSON instead of pipe-delimited lines.
- `chezmoi/dot_config/colorice/templates/eww-colors.scss` — new colorice
  template, reused by sub-projects 2 and 3.
- `ansible/group_vars/all/packages.yml` — `eww` added.

**Merge commits:** `86e05c1` (JSON nowplaying stream), `1e937c6` (daemon
config + animation toolkit), `6f52518` (nowplaying widget), `dcdfd3c` (wire
into polybar launch/click), `be364f5` (deferred-minor fixups).

**Spec:** `docs/superpowers/specs/2026-08-15-eww-animation-toolkit-media-widget-design.md`.

---

## Sub-project 2: Volume/quick-settings popup — DONE (merged)

No tasks here — already implemented and merged to `main`. Reference only.

**Files delivered:**
- `chezmoi/dot_config/eww/scripts/executable_volume-status.sh` — one-shot
  `pactl` volume/mute reader.
- `chezmoi/dot_config/eww/widgets/volume.yuck` / `.scss` — slider + mute
  button widget.
- `chezmoi/dot_config/eww/eww.yuck` (extended) — `volume-popup-visible`
  var, `volume-popup` window.
- `chezmoi/dot_config/polybar/executable_launch.sh`,
  `chezmoi/dot_config/polybar/config.ini` — wired click-left toggle + popup
  open at startup.

**Merge commits:** `574b472` (pactl status script), `7b94bf5` (daemon
config), `432182d` (volume widget), `bae1e70` (wire into launch/click),
merged via `a8e0aac` (`Merge branch 'eww-volume-popup'`).

**Spec:** `docs/superpowers/specs/2026-08-15-eww-volume-popup-design.md`.

---

## Sub-project 3: Sysinfo drawer — SPEC'D + PLANNED, NOT YET IMPLEMENTED

Tasks below are reproduced verbatim from
`docs/superpowers/plans/2026-08-16-eww-sysinfo-drawer.md` (itself built from
`docs/superpowers/specs/2026-08-16-eww-sysinfo-drawer-design.md`) so this
consolidated doc is a complete, standalone checklist. No implementation
commits exist for these files yet — `chezmoi/dot_config/eww/widgets/sysinfo.*`
and `chezmoi/dot_config/eww/scripts/executable_sysinfo-status.sh` do not
exist on disk as of this writing.

**Sub-project-3-specific constraints** (in addition to the Global Constraints
above):
- `[module/cpu]`, `[module/memory]`, `[module/temperature]`, `[module/gpu]`
  are removed entirely from `chezmoi/dot_config/polybar/config.ini` — a
  deliberate, confirmed deviation from sub-projects 1–2's "augment, don't
  replace" default.
- The drawer is read-only — no interactive controls, unlike volume's
  slider/mute button.
- `amdgpu_top` JSON field paths for GPU temperature and VRAM (beyond the
  already-known `.devices[0].gpu_activity.GFX.value` for GPU %) are
  unverified against real hardware in this dev sandbox — Task 3.1 writes
  parsing logic against the spec's best-guess field names and falls back to
  `null` if a field is absent, rather than blocking on hardware access this
  sandbox doesn't have.

### Task 3.1: `sysinfo-status.sh` script

**Files:**
- Create: `chezmoi/dot_config/eww/scripts/executable_sysinfo-status.sh`

**Interfaces:**
- Produces: stdout JSON `{"cpu_percent": <int>, "load_avg": [<float>,
  <float>, <float>], "mem_used_mb": <int>, "mem_total_mb": <int>,
  "gpu_percent": <int|null>, "gpu_temp_c": <int|null>, "vram_used_mb":
  <int|null>, "vram_total_mb": <int|null>, "cpu_temp_c": <int|null>,
  "uptime": <string>}` — one line, printed once per invocation (not a
  loop) — consumed by Task 3.2's `defpoll`.

- [ ] **Step 1: Write the script**

Create `chezmoi/dot_config/eww/scripts/executable_sysinfo-status.sh`:

```bash
#!/bin/bash
# One-shot system-stats reader for eww's defpoll (Task 3.2). Not a daemon —
# invoked fresh on each poll tick while the sysinfo drawer is visible.
# Every field falls back to 0/null on read failure rather than aborting
# the whole script — one missing sensor shouldn't blank the whole drawer.

# --- CPU percent: two /proc/stat samples ~100ms apart ---
read_cpu_total_idle() {
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    echo "$total $idle"
}

read t1_total t1_idle < <(read_cpu_total_idle)
sleep 0.1
read t2_total t2_idle < <(read_cpu_total_idle)

total_delta=$((t2_total - t1_total))
idle_delta=$((t2_idle - t1_idle))

if [ "$total_delta" -gt 0 ]; then
    cpu_percent=$(( (100 * (total_delta - idle_delta)) / total_delta ))
else
    cpu_percent=0
fi

# --- Load average ---
load_raw=$(cat /proc/loadavg 2>/dev/null)
load1=$(echo "$load_raw" | awk '{print $1}')
load5=$(echo "$load_raw" | awk '{print $2}')
load15=$(echo "$load_raw" | awk '{print $3}')
[ -z "$load1" ] && load1=0
[ -z "$load5" ] && load5=0
[ -z "$load15" ] && load15=0

# --- Memory ---
mem_raw=$(free -m 2>/dev/null | awk '/^Mem:/ {print $2, $3}')
mem_total_mb=$(echo "$mem_raw" | awk '{print $1}')
mem_used_mb=$(echo "$mem_raw" | awk '{print $2}')
[ -z "$mem_total_mb" ] && mem_total_mb=0
[ -z "$mem_used_mb" ] && mem_used_mb=0

# --- GPU (amdgpu_top, same source/perms caveat as today's [module/gpu]) ---
gpu_json=$(amdgpu_top --json -n 1 2>/dev/null)
gpu_percent=$(echo "$gpu_json" | jq -r '.devices[0].gpu_activity.GFX.value // empty' 2>/dev/null)
gpu_temp_c=$(echo "$gpu_json" | jq -r '.devices[0].sensors.Temperature.value // empty' 2>/dev/null)
vram_used_mb=$(echo "$gpu_json" | jq -r '.devices[0].VRAM.Usage.value // empty' 2>/dev/null)
vram_total_mb=$(echo "$gpu_json" | jq -r '.devices[0].VRAM.Total_VRAM.value // empty' 2>/dev/null)
[ -z "$gpu_percent" ] && gpu_percent=null
[ -z "$gpu_temp_c" ] && gpu_temp_c=null
[ -z "$vram_used_mb" ] && vram_used_mb=null
[ -z "$vram_total_mb" ] && vram_total_mb=null

# --- CPU temperature (same thermal zone as today's [module/temperature]) ---
cpu_temp_raw=$(cat /sys/class/thermal/thermal_zone2/temp 2>/dev/null)
if [ -n "$cpu_temp_raw" ]; then
    cpu_temp_c=$((cpu_temp_raw / 1000))
else
    cpu_temp_c=null
fi

# --- Uptime ---
uptime_seconds=$(cat /proc/uptime 2>/dev/null | awk '{print int($1)}')
if [ -n "$uptime_seconds" ]; then
    days=$((uptime_seconds / 86400))
    hours=$(((uptime_seconds % 86400) / 3600))
    uptime_str="${days}d ${hours}h"
else
    uptime_str="unknown"
fi

python3 -c "
import json, sys

def numish(v):
    if v == 'null':
        return None
    try:
        return int(v)
    except ValueError:
        return float(v)

print(json.dumps({
    'cpu_percent': int(sys.argv[1]),
    'load_avg': [float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])],
    'mem_used_mb': int(sys.argv[5]),
    'mem_total_mb': int(sys.argv[6]),
    'gpu_percent': numish(sys.argv[7]),
    'gpu_temp_c': numish(sys.argv[8]),
    'vram_used_mb': numish(sys.argv[9]),
    'vram_total_mb': numish(sys.argv[10]),
    'cpu_temp_c': numish(sys.argv[11]),
    'uptime': sys.argv[12],
}))
" "$cpu_percent" "$load1" "$load5" "$load15" "$mem_used_mb" "$mem_total_mb" \
  "$gpu_percent" "$gpu_temp_c" "$vram_used_mb" "$vram_total_mb" "$cpu_temp_c" "$uptime_str"
```

- [ ] **Step 2: Make it executable and verify syntax**

Run: `chmod +x chezmoi/dot_config/eww/scripts/executable_sysinfo-status.sh`
Run: `bash -n chezmoi/dot_config/eww/scripts/executable_sysinfo-status.sh`
Expected: no output, exit code 0.

- [ ] **Step 3: Smoke test**

Run: `bash chezmoi/dot_config/eww/scripts/executable_sysinfo-status.sh`
Expected: one line of valid JSON with all ten keys present (`cpu_percent`,
`load_avg`, `mem_used_mb`, `mem_total_mb`, `gpu_percent`, `gpu_temp_c`,
`vram_used_mb`, `vram_total_mb`, `cpu_temp_c`, `uptime`). GPU/CPU-temp
fields may be `null` if `amdgpu_top`/thermal zone are unavailable in this
sandbox — that is a pass, the point is valid JSON with every key present.

Verify it's valid JSON with all keys present:
```bash
bash chezmoi/dot_config/eww/scripts/executable_sysinfo-status.sh | python3 -c "
import json, sys
d = json.load(sys.stdin)
required = ['cpu_percent', 'load_avg', 'mem_used_mb', 'mem_total_mb',
            'gpu_percent', 'gpu_temp_c', 'vram_used_mb', 'vram_total_mb',
            'cpu_temp_c', 'uptime']
missing = [k for k in required if k not in d]
assert not missing, f'missing keys: {missing}'
assert isinstance(d['load_avg'], list) and len(d['load_avg']) == 3
print('OK')
"
```
Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add chezmoi/dot_config/eww/scripts/executable_sysinfo-status.sh
git commit -m "Add one-shot system-stats script for eww sysinfo drawer"
```

---

### Task 3.2: eww daemon config — sysinfo state + window

**Files:**
- Modify: `chezmoi/dot_config/eww/eww.yuck`
- Modify: `chezmoi/dot_config/eww/eww.scss`

**Interfaces:**
- Consumes: `chezmoi/dot_config/eww/scripts/executable_sysinfo-status.sh`
  (Task 3.1).
- Produces: `defvar sysinfo-popup-visible` (bool), `defwindow
  sysinfo-popup` — consumed by Task 3.3's widget and Task 3.4's polybar
  click handler + launch.sh.

- [ ] **Step 1: Add the include and state to `eww.yuck`**

In `chezmoi/dot_config/eww/eww.yuck`, change:

```lisp
(include "./widgets/nowplaying.yuck")
(include "./widgets/volume.yuck")
```

to:

```lisp
(include "./widgets/nowplaying.yuck")
(include "./widgets/volume.yuck")
(include "./widgets/sysinfo.yuck")
```

Then, after the existing `defwindow volume-popup` block (end of file),
append:

```lisp

;; Drives the sysinfo-popup's revealer, same pattern as
;; volume-popup-visible above — the window stays open permanently, this
;; var toggles it.
(defvar sysinfo-popup-visible false)

;; System stats — polled only while the popup is visible, one script
;; call per tick, no persistent background process.
(defpoll sysinfo_json :interval "2s"
                       :initial "{\"cpu_percent\": 0, \"load_avg\": [0, 0, 0], \"mem_used_mb\": 0, \"mem_total_mb\": 0, \"gpu_percent\": null, \"gpu_temp_c\": null, \"vram_used_mb\": null, \"vram_total_mb\": null, \"cpu_temp_c\": null, \"uptime\": \"\"}"
                       :run-while sysinfo-popup-visible
  `~/.config/eww/scripts/sysinfo-status.sh`)

(defwindow sysinfo-popup
  :monitor 0
  :geometry (geometry :x "0px"
                       :y "29px"
                       :width "260px"
                       :height "220px"
                       :anchor "bottom center")
  :stacking "fg"
  :wm-ignore true
  (sysinfo :json sysinfo_json
           :visible sysinfo-popup-visible))
```

- [ ] **Step 2: Add the import to `eww.scss`**

In `chezmoi/dot_config/eww/eww.scss`, change:

```scss
@import "widgets/nowplaying.scss";
@import "widgets/volume.scss";
```

to:

```scss
@import "widgets/nowplaying.scss";
@import "widgets/volume.scss";
@import "widgets/sysinfo.scss";
```

- [ ] **Step 3: Manual paren/brace balance check**

Count opening/closing parens in the added `eww.yuck` block and confirm
they're equal (the added block is 5 `(` and 5 `)` — spot-check by eye or
with a quick counter). Confirm `eww.scss`'s added `@import` line has
correct syntax (semicolon, matching quote style to the existing lines).

If an `eww` binary happens to be available:
Run: `eww --config chezmoi/dot_config/eww validate`
Expected: exit 0 (will still fail until Task 3.3 creates
`widgets/sysinfo.yuck`/`.scss` — if so, note it as expected-until-Task-3.3
and move on, this isn't a blocker for this task).

- [ ] **Step 4: Commit**

```bash
git add chezmoi/dot_config/eww/eww.yuck chezmoi/dot_config/eww/eww.scss
git commit -m "Add sysinfo popup state + window to eww daemon config"
```

---

### Task 3.3: sysinfo widget

**Files:**
- Create: `chezmoi/dot_config/eww/widgets/sysinfo.yuck`
- Create: `chezmoi/dot_config/eww/widgets/sysinfo.scss`

**Interfaces:**
- Consumes: `:json` (JSON string, fields `cpu_percent`/`load_avg`/
  `mem_used_mb`/`mem_total_mb`/`gpu_percent`/`gpu_temp_c`/
  `vram_used_mb`/`vram_total_mb`/`cpu_temp_c`/`uptime`), `:visible`
  (bool) — attribute names must match Task 3.2's `(sysinfo :json
  sysinfo_json :visible sysinfo-popup-visible)` call exactly.
- Consumes SCSS vars from `animations.scss` and `colorice-colors.scss`
  (`$base`, `$text`, `$subtext0`, `$surface0`, `$overlay1`, `$red`,
  `$peach`, `$mauve` — same vars `nowplaying.scss`/`volume.scss` already
  use, all defined in
  `chezmoi/dot_config/colorice/templates/eww-colors.scss`).

- [ ] **Step 1: Write `sysinfo.yuck`**

Create `chezmoi/dot_config/eww/widgets/sysinfo.yuck`:

```lisp
(defwidget sysinfo [json visible]
  (revealer :transition "slideup"
            :duration "250ms"
            :reveal visible
    (box :class "sysinfo-popup"
         :orientation "vertical"
         :space-evenly false
      (box :class "sysinfo-row" :orientation "horizontal" :space-evenly false
        (label :class "sysinfo-icon sysinfo-icon-cpu" :text "󰻠")
        (label :class "sysinfo-label" :text "CPU  ${round(json.cpu_percent, 0)}%  (load ${json.load_avg[0]} ${json.load_avg[1]} ${json.load_avg[2]})"))
      (box :class "sysinfo-row" :orientation "horizontal" :space-evenly false
        (label :class "sysinfo-icon sysinfo-icon-mem" :text "")
        (label :class "sysinfo-label" :text "Mem  ${json.mem_used_mb} / ${json.mem_total_mb} MB"))
      (box :class "sysinfo-row" :orientation "horizontal" :space-evenly false
        (label :class "sysinfo-icon sysinfo-icon-gpu" :text "󰢮")
        (label :class "sysinfo-label" :text "GPU  ${json.gpu_percent != null ? \"${json.gpu_percent}%\" : \"n/a\"}  ${json.vram_used_mb != null ? \"(${json.vram_used_mb} / ${json.vram_total_mb} MB)\" : \"\"}"))
      (box :class "sysinfo-row" :orientation "horizontal" :space-evenly false
        (label :class "sysinfo-icon sysinfo-icon-temp" :text "")
        (label :class "sysinfo-label" :text "Temp  CPU ${json.cpu_temp_c != null ? \"${json.cpu_temp_c}°C\" : \"n/a\"}  GPU ${json.gpu_temp_c != null ? \"${json.gpu_temp_c}°C\" : \"n/a\"}"))
      (box :class "sysinfo-row" :orientation "horizontal" :space-evenly false
        (label :class "sysinfo-icon sysinfo-icon-uptime" :text "󰅐")
        (label :class "sysinfo-label" :text "Uptime  ${json.uptime}")))))
```

- [ ] **Step 2: Write `sysinfo.scss`**

Create `chezmoi/dot_config/eww/widgets/sysinfo.scss`:

```scss
.sysinfo-popup {
  background-color: $base;
  color: $text;
  border-radius: 8px;
  padding: 8px;
}

.sysinfo-row {
  margin-bottom: 4px;
}

.sysinfo-icon {
  margin-right: 8px;
  min-width: 16px;
}

.sysinfo-icon-cpu {
  color: $red;
}

.sysinfo-icon-mem, .sysinfo-icon-temp {
  color: $peach;
}

.sysinfo-icon-gpu {
  color: $mauve;
}

.sysinfo-icon-uptime {
  color: $overlay1;
}

.sysinfo-label {
  color: $text;
  font-size: 0.85em;
}
```

- [ ] **Step 3: Validate the full eww config**

Manually re-count `eww.yuck` + `sysinfo.yuck` parens (already balanced
individually — `sysinfo.yuck` has 21 `(`/21 `)`) and `sysinfo.scss`
braces (8 rule blocks, 8 `{`/8 `}`).

If an `eww` binary happens to be available:
Run: `eww --config chezmoi/dot_config/eww validate`
Expected: exit code 0, no yuck/scss errors. (Same caveat as sub-projects
1–2 — likely unavailable in a dev sandbox; on this dev machine, symlink or
copy `ansible/roles/colorice/files/seed/eww-colorice-colors.scss` to
`~/.config/eww/colorice-colors.scss` first if it doesn't already exist,
same as sub-project 1's Task 7.)

- [ ] **Step 4: Commit**

```bash
git add chezmoi/dot_config/eww/widgets/sysinfo.yuck chezmoi/dot_config/eww/widgets/sysinfo.scss
git commit -m "Add sysinfo widget"
```

---

### Task 3.4: Wire polybar to the sysinfo drawer, remove old modules

**Files:**
- Modify: `chezmoi/dot_config/polybar/executable_launch.sh`
- Modify: `chezmoi/dot_config/polybar/config.ini`

**Interfaces:**
- Consumes: `sysinfo-popup` window + `sysinfo-popup-visible` var (Task 3.2).

- [ ] **Step 1: Open the popup at daemon startup**

In `chezmoi/dot_config/polybar/executable_launch.sh`, change:

```bash
eww open nowplaying-popup
eww open volume-popup

polybar main &
```

to:

```bash
eww open nowplaying-popup
eww open volume-popup
eww open sysinfo-popup

polybar main &
```

- [ ] **Step 2: Remove the four old modules and update `modules-center`**

In `chezmoi/dot_config/polybar/config.ini`:

Change line 48:
```ini
modules-center = nowplaying temperature memory date cpu gpu
```
to:
```ini
modules-center = nowplaying sysinfo date
```

Delete the `[module/memory]` section (lines 161-168):
```ini
[module/memory]
type = internal/memory
interval = 2
format-prefix = " "
format-prefix-foreground = ${colors.peach}
format-background = ${colors.surface0}
format-padding = 1
label = %percentage_used:2%%
```

Delete the `[module/cpu]` section (lines 170-177):
```ini
[module/cpu]
type = internal/cpu
interval = 2
format-prefix = " "
format-prefix-foreground = ${colors.red}
format-background = ${colors.surface0}
format-padding = 1
label = %percentage:2%%
```

Delete the `[module/temperature]` section (lines 196-215):
```ini
[module/temperature]
type = internal/temperature
thermal-zone = 2
warn-temperature = 80

format = <label>
format-background = ${colors.surface0}
format-padding = 1
format-prefix = " "
format-prefix-foreground = ${colors.peach}
label = %temperature-c:0%

format-warn = <label-warn>
format-warn-background = ${colors.surface0}
format-warn-padding = 1
format-warn-prefix = " "
format-warn-prefix-foreground = ${colors.red}
label-warn = %temperature-c:0%
label-warn-foreground = ${colors.red}
```

Delete the `[module/gpu]` section, including its preceding `ponytail:`
comment (lines 216-227):
```ini
; ponytail: amdgpu_top needs perf-counter access (root, or CAP_PERFMON on the
; binary) on the real AMD box, else this silently reads blank. setcap when deployed.
[module/gpu]
type = custom/script
exec = amdgpu_top --json -n 1 2>/dev/null | jq -r '.devices[0].gpu_activity.GFX.value'
interval = 2

format = <label>
format-background = ${colors.surface0}
format-padding = 1
format-prefix = " "
format-prefix-foreground = ${colors.mauve}
label = %output%%
```

In their place (where `[module/memory]` used to start), add the new
`[module/sysinfo]` section:

```ini
[module/sysinfo]
type = custom/text
content = 󰍛
content-background = ${colors.surface0}
content-padding = 1
content-foreground = ${colors.mauve}

click-left = eww update sysinfo-popup-visible=$([ "$(eww get sysinfo-popup-visible)" = "true" ] && echo false || echo true)
```

- [ ] **Step 3: Verify shell syntax**

Run: `bash -n chezmoi/dot_config/polybar/executable_launch.sh`
Expected: no output, exit code 0.

- [ ] **Step 4: Verify polybar config still parses (if `polybar` binary available)**

Run: `polybar --config=chezmoi/dot_config/polybar/config.ini -m 2>&1 | head -5`
Expected: no `error while parsing` output, and no reference to the removed
`cpu`/`memory`/`temperature`/`gpu` module names anywhere else in the file
(check with `grep -n "cpu\|memory\|temperature\|module/gpu"
chezmoi/dot_config/polybar/config.ini` — the only remaining hits should be
unrelated, e.g. none expected). If `polybar`/a display isn't available in
this environment (headless dev sandbox), note that and move on — same
caveat as sub-project 1's Task 8.

- [ ] **Step 5: Commit**

```bash
git add chezmoi/dot_config/polybar/executable_launch.sh chezmoi/dot_config/polybar/config.ini
git commit -m "Replace cpu/memory/temperature/gpu polybar modules with sysinfo drawer"
```

---

### Task 3.5: Verification checkpoint

**Files:** none (verification only).

**Interfaces:** none.

- [ ] **Step 1: Ansible syntax check (expected no-op — no ansible files touched this sub-project)**

Run: `ansible-playbook ansible/site.yml --syntax-check`
Expected: exit code 0.

- [ ] **Step 2: chezmoi dry-run diff**

Run: `chezmoi diff --source chezmoi 2>&1 | head -200`
Expected: diff shows the new/changed files from Tasks 3.1-3.4
(eww/scripts/sysinfo-status.sh, eww/{eww.yuck,eww.scss,
widgets/sysinfo.{yuck,scss}}, polybar/{config.ini,launch.sh}), no errors.

- [ ] **Step 3: Full eww config validation (if `eww` binary available)**

Run: `eww --config chezmoi/dot_config/eww validate`
Expected: exit code 0.

- [ ] **Step 4: Report to user, do not apply live**

Tell the user: all syntax/dry-run checks pass; a real `ansible-playbook
site.yml` run or `chezmoi apply` + live `eww`/`polybar` restart is needed
to see the drawer live — that run is the user's call, not part of this
plan. Also flag: `amdgpu_top` field paths for GPU temp/VRAM (Task 3.1) are
unverified against real hardware — worth a manual check on first live run
that those two fields aren't silently `null` when they shouldn't be.

---

## Sub-projects 4–7: tray/powermenu, notification center, calendar, + 1 open slot — NOT PLANNED

The master spec (`docs/superpowers/specs/2026-08-15-eww-animation-toolkit-media-widget-design.md`)
names these as future sub-projects but does not design them — no goals,
architecture, components, or data sources are defined for any of the four.
Per this plan skill's rule against placeholder tasks ("TBD", "similar to
sub-project N", steps with no real content), **no implementation tasks are
written here** — doing so would mean fabricating architecture that hasn't
been decided.

Before any of these can get a plan like sub-project 3's:

1. Run `superpowers:brainstorming` per sub-project to pin down goals,
   architecture, and components — same process sub-projects 1–3 went
   through (see their `docs/superpowers/specs/*-design.md` files).
2. Write the resulting spec to
   `docs/superpowers/specs/YYYY-MM-DD-eww-<name>-design.md`.
3. Run `superpowers:writing-plans` again against that spec to add a
   `Sub-project N` section to this document, following sub-project 3's
   structure above (numbered tasks, full code in every step, no
   placeholders).

**What's known from the master spec's non-goals list, not yet a design:**
- **Sub-project 4 — tray + powermenu popup:** system tray icons +
  shutdown/reboot/lock/logout menu, likely one popup or two adjacent ones.
- **Sub-project 5 — notification center:** likely built on `dunst` or
  similar, no notification daemon choice made yet.
- **Sub-project 6 — calendar popup:** no data source (local ICS? a CLI
  calendar tool?) chosen yet.
- **Sub-project 7 — open slot:** the master spec's title says "7 sub-
  projects" but only 6 are named across the two specs read for this plan;
  the 7th is unassigned. Confirm with the repo owner what it is before
  scoping it.
