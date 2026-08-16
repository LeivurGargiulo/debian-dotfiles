# Eww Volume/Mute Popup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a click-triggered eww popup for volume control (slider +
mute toggle) on polybar's `pulseaudio` module, reusing sub-project 1's
animation toolkit and colorice palette.

**Architecture:** Same pattern as the media popup: a persistent
`wm-ignore true` eww window wrapped in a `revealer`, opened once at
daemon startup, toggled via a `defvar` that polybar's `click-left` flips.
A new one-shot script (`volume-status.sh`) queries `pactl` for volume/mute
state; an eww `defpoll` (`:run-while volume-popup-visible`) polls it only
while the popup is open — no new persistent background process. A `scale`
widget drives `pactl set-sink-volume`; a button drives
`pactl set-sink-mute toggle`.

**Tech Stack:** eww (yuck + SCSS), pactl (pulseaudio-utils, already
installed), bash, python3 (JSON emission, matching sub-project 1's
convention).

**Spec:** `docs/superpowers/specs/2026-08-16-eww-volume-popup-design.md`

## Global Constraints

- No new colorice template — reuses `~/.config/eww/colorice-colors.scss`
  and `chezmoi/dot_config/eww/animations.scss` from sub-project 1 as-is.
- No new persistent background process — volume state is polled via
  `defpoll :run-while volume-popup-visible`, not an always-running
  `pactl subscribe` stream (unlike `mpris-daemon.sh`'s `--follow` loop).
- `click-right = pavucontrol` on `[module/pulseaudio]` stays untouched —
  this popup is additive, not a replacement for the full mixer.
- This is an infra/config repo with no application test suite. "Tests"
  are `bash -n`, a standalone script smoke test, `ansible-playbook
  --syntax-check` (expected no-op here — no ansible files touched), and
  manual yuck/scss paren/brace balance checks — run these instead of unit
  tests, per sub-project 1's established convention.
- No `eww` binary is available in the dev sandbox this plan is likely to
  be executed in (same as sub-project 1) — `eww validate` steps are
  best-effort/deferred to a provisioned machine, not a blocker.
- Do not run a real (non-dry-run) `ansible-playbook site.yml` apply or a
  live `eww`/`polybar` restart against a real machine as part of any task
  in this plan.

---

### Task 1: `volume-status.sh` script

**Files:**
- Create: `chezmoi/dot_config/eww/scripts/executable_volume-status.sh`

**Interfaces:**
- Produces: stdout JSON `{"volume": <int 0-100>, "muted": <bool>}` — one
  line, printed once per invocation (not a loop) — consumed by Task 2's
  `defpoll`.

- [ ] **Step 1: Write the script**

Create `chezmoi/dot_config/eww/scripts/executable_volume-status.sh`:

```bash
#!/bin/bash
# One-shot volume/mute reader for eww's defpoll (Task 2). Not a daemon —
# invoked fresh on each poll tick while the volume popup is visible.

vol_raw=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null)
mute_raw=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)

vol=$(echo "$vol_raw" | grep -oP '\d+(?=%)' | head -1)
[ -z "$vol" ] && vol=0

if echo "$mute_raw" | grep -q "yes"; then
    muted=true
else
    muted=false
fi

python3 -c "import json, sys; print(json.dumps({'volume': int(sys.argv[1]), 'muted': sys.argv[2] == 'true'}))" "$vol" "$muted"
```

- [ ] **Step 2: Make it executable and verify syntax**

Run: `chmod +x chezmoi/dot_config/eww/scripts/executable_volume-status.sh`
Run: `bash -n chezmoi/dot_config/eww/scripts/executable_volume-status.sh`
Expected: no output, exit code 0.

- [ ] **Step 3: Smoke test**

Run: `bash chezmoi/dot_config/eww/scripts/executable_volume-status.sh`
Expected: one line of valid JSON matching `{"volume": N, "muted": true|false}`
(if no `pactl`/sink is available in this environment, expected output is
the fallback `{"volume": 0, "muted": false}` — either is a pass, the
point is valid JSON with both keys present).

Verify it's valid JSON either way:
```bash
bash chezmoi/dot_config/eww/scripts/executable_volume-status.sh | python3 -c "import json, sys; d = json.load(sys.stdin); assert 'volume' in d and 'muted' in d; print('OK')"
```
Expected: `OK`.

- [ ] **Step 4: Commit**

```bash
git add chezmoi/dot_config/eww/scripts/executable_volume-status.sh
git commit -m "Add one-shot pactl volume/mute status script for eww"
```

---

### Task 2: eww daemon config — volume state + window

**Files:**
- Modify: `chezmoi/dot_config/eww/eww.yuck`
- Modify: `chezmoi/dot_config/eww/eww.scss`

**Interfaces:**
- Consumes: `chezmoi/dot_config/eww/scripts/executable_volume-status.sh`
  (Task 1).
- Produces: `defvar volume-popup-visible` (bool), `defwindow volume-popup`
  — consumed by Task 3's widget and Task 4's polybar click handler +
  launch.sh.

- [ ] **Step 1: Add the include and state to `eww.yuck`**

In `chezmoi/dot_config/eww/eww.yuck`, change:

```lisp
(include "./widgets/nowplaying.yuck")
```

to:

```lisp
(include "./widgets/nowplaying.yuck")
(include "./widgets/volume.yuck")
```

Then, after the existing `defwindow nowplaying-popup` block (end of
file), append:

```lisp

;; Drives the volume-popup's revealer, same pattern as popup-visible
;; above — the window stays open permanently, this var toggles it.
(defvar volume-popup-visible false)

;; Volume/mute state — polled only while the popup is visible, one
;; pactl-based script call per tick, no persistent background process.
(defpoll volume_json :interval "1s"
                      :initial "{\"volume\": 0, \"muted\": false}"
                      :run-while volume-popup-visible
  `~/.config/eww/scripts/volume-status.sh`)

(defwindow volume-popup
  :monitor 0
  :geometry (geometry :x "0px"
                       :y "29px"
                       :width "220px"
                       :height "100px"
                       :anchor "bottom right")
  :stacking "fg"
  :wm-ignore true
  (volume :json volume_json
          :visible volume-popup-visible))
```

- [ ] **Step 2: Add the import to `eww.scss`**

In `chezmoi/dot_config/eww/eww.scss`, change:

```scss
@import "widgets/nowplaying.scss";
```

to:

```scss
@import "widgets/nowplaying.scss";
@import "widgets/volume.scss";
```

- [ ] **Step 3: Manual paren/brace balance check**

Count opening/closing parens in `eww.yuck` and confirm they're equal
(the file should have no unmatched `(`/`)` — the added block is 10 `(`
and 10 `)`, spot-check by eye or with a quick counter). Confirm
`eww.scss`'s added `@import` line has correct syntax (semicolon,
matching quote style to the existing lines).

If an `eww` binary happens to be available:
Run: `eww --config chezmoi/dot_config/eww validate`
Expected: exit 0 (will still fail until Task 3 creates
`widgets/volume.yuck`/`.scss` — if so, note it as expected-until-Task-3
and move on, this isn't a blocker for this task).

- [ ] **Step 4: Commit**

```bash
git add chezmoi/dot_config/eww/eww.yuck chezmoi/dot_config/eww/eww.scss
git commit -m "Add volume popup state + window to eww daemon config"
```

---

### Task 3: volume widget

**Files:**
- Create: `chezmoi/dot_config/eww/widgets/volume.yuck`
- Create: `chezmoi/dot_config/eww/widgets/volume.scss`

**Interfaces:**
- Consumes: `:json` (JSON string, fields `volume`/`muted`), `:visible`
  (bool) — attribute names must match Task 2's `(volume :json volume_json
  :visible volume-popup-visible)` call exactly.
- Consumes SCSS vars from `animations.scss` and `colorice-colors.scss`
  (`$base`, `$text`, `$mauve`, `$surface0`, `$overlay1` — same vars
  `nowplaying.scss` already uses, all defined in
  `chezmoi/dot_config/colorice/templates/eww-colors.scss`).

- [ ] **Step 1: Write `volume.yuck`**

Create `chezmoi/dot_config/eww/widgets/volume.yuck`:

```lisp
(defwidget volume [json visible]
  (revealer :transition "slideup"
            :duration "250ms"
            :reveal visible
    (box :class "volume-popup"
         :orientation "vertical"
         :space-evenly false
      (box :class "volume-row"
           :orientation "horizontal"
           :space-evenly false
        (button :class "volume-mute-btn eww-fade-hover"
                :onclick "pactl set-sink-mute @DEFAULT_SINK@ toggle"
                {json.muted ? "󰝟" : "󰕾"})
        (scale :class "volume-scale"
               :value {json.volume}
               :min 0
               :max 100
               :onchange "pactl set-sink-volume @DEFAULT_SINK@ {}%"))
      (label :class "volume-label" :text "${json.volume}%"))))
```

- [ ] **Step 2: Write `volume.scss`**

Create `chezmoi/dot_config/eww/widgets/volume.scss`:

```scss
.volume-popup {
  background-color: $base;
  color: $text;
  border-radius: 8px;
  padding: 8px;
}

.volume-row {
  margin-bottom: 4px;
}

.volume-mute-btn {
  background-color: $surface0;
  color: $mauve;
  border-radius: 6px;
  padding: 4px 8px;
  margin-right: 8px;
}

.volume-scale {
  min-width: 140px;
}

.volume-label {
  color: $overlay1;
  font-size: 0.8em;
}
```

- [ ] **Step 3: Validate the full eww config**

Manually re-count `eww.yuck` + `volume.yuck` parens (already balanced
individually — `volume.yuck` has 13 `(`/13 `)`) and `volume.scss`
braces (4 rule blocks, 4 `{`/4 `}`).

If an `eww` binary happens to be available:
Run: `eww --config chezmoi/dot_config/eww validate`
Expected: exit code 0, no yuck/scss errors. (Same caveat as sub-project
1 — likely unavailable in a dev sandbox; on this dev machine, symlink or
copy `ansible/roles/colorice/files/seed/eww-colorice-colors.scss` to
`~/.config/eww/colorice-colors.scss` first if it doesn't already exist,
same as sub-project 1's Task 7.)

- [ ] **Step 4: Commit**

```bash
git add chezmoi/dot_config/eww/widgets/volume.yuck chezmoi/dot_config/eww/widgets/volume.scss
git commit -m "Add volume widget"
```

---

### Task 4: Wire polybar + launch.sh to the volume popup

**Files:**
- Modify: `chezmoi/dot_config/polybar/executable_launch.sh`
- Modify: `chezmoi/dot_config/polybar/config.ini`

**Interfaces:**
- Consumes: `volume-popup` window + `volume-popup-visible` var (Task 2).

- [ ] **Step 1: Open the popup at daemon startup**

In `chezmoi/dot_config/polybar/executable_launch.sh`, change:

```bash
eww open nowplaying-popup

polybar main &
```

to:

```bash
eww open nowplaying-popup
eww open volume-popup

polybar main &
```

- [ ] **Step 2: Add the `pulseaudio` module's click-left**

In `chezmoi/dot_config/polybar/config.ini`, in the `[module/pulseaudio]`
section, find:

```ini
click-right = pavucontrol
```

and change it to:

```ini
click-left = eww update volume-popup-visible=$([ "$(eww get volume-popup-visible)" = "true" ] && echo false || echo true)
click-right = pavucontrol
```

- [ ] **Step 3: Verify shell syntax**

Run: `bash -n chezmoi/dot_config/polybar/executable_launch.sh`
Expected: no output, exit code 0.

- [ ] **Step 4: Verify polybar config still parses (if `polybar` binary available)**

Run: `polybar --config=chezmoi/dot_config/polybar/config.ini -m 2>&1 | head -5`
Expected: no `error while parsing` output. If `polybar`/a display isn't
available in this environment (headless dev sandbox), note that and move
on — same caveat as sub-project 1's Task 8.

- [ ] **Step 5: Commit**

```bash
git add chezmoi/dot_config/polybar/executable_launch.sh chezmoi/dot_config/polybar/config.ini
git commit -m "Wire volume popup into polybar launch/click"
```

---

### Task 5: Verification checkpoint

**Files:** none (verification only).

**Interfaces:** none.

- [ ] **Step 1: Ansible syntax check (expected no-op — no ansible files touched this plan)**

Run: `ansible-playbook ansible/site.yml --syntax-check`
Expected: exit code 0.

- [ ] **Step 2: chezmoi dry-run diff**

Run: `chezmoi diff --source chezmoi 2>&1 | head -150`
Expected: diff shows the new/changed files from Tasks 1-4 (eww/scripts/
volume-status.sh, eww/{eww.yuck,eww.scss,widgets/volume.{yuck,scss}},
polybar/{config.ini,launch.sh}), no errors.

- [ ] **Step 3: Full eww config validation (if `eww` binary available)**

Run: `eww --config chezmoi/dot_config/eww validate`
Expected: exit code 0.

- [ ] **Step 4: Report to user, do not apply live**

Tell the user: all syntax/dry-run checks pass; a real `ansible-playbook
site.yml` run or `chezmoi apply` + live `eww`/`polybar` restart is needed
to see the popup live — that run is the user's call, not part of this
plan.
