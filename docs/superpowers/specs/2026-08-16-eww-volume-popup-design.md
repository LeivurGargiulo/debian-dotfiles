# Eww volume/mute popup (sub-project 2 of 7)

## Context

Second of the eww-widgets sub-projects (see
`docs/superpowers/specs/2026-08-15-eww-animation-toolkit-media-widget-design.md`
for the full 7-part decomposition and the shared animation toolkit this
reuses). Sub-project 1 (media popup) is implemented and merged: polybar's
`nowplaying` module toggles an eww popup via a `popup-visible`-style var,
using a persistent `wm-ignore true` window wrapped in a `revealer`. This
sub-project applies the exact same pattern to polybar's `pulseaudio`
module.

## Goals

- Add a click-triggered eww popup for volume control: a draggable slider
  and a mute toggle.
- Reuse the existing animation toolkit (`animations.scss`) and colorice
  palette (`colorice-colors.scss`) from sub-project 1 — no new colorice
  template needed.
- Keep `pulseaudio`'s existing `click-right = pavucontrol` (full GUI
  mixer) untouched — this popup is an additive quick-control, not a
  pavucontrol replacement.

## Non-goals

- No wifi/brightness/other quick-settings toggles in this popup — those
  have no existing polybar module to hang a click off of yet; out of
  scope until/unless a future sub-project adds them.
- No event-driven `pactl subscribe` daemon — volume changes are
  user-driven and infrequent; a poll gated to "only while the popup is
  open" is sufficient and avoids a second always-running background
  process.
- The other 5 remaining sub-projects (sysinfo drawer, tray/powermenu,
  notification center, calendar) — future specs.

## Architecture

Polybar's `[module/pulseaudio]` gains `click-left`, toggling a new
`volume-popup-visible` eww var — same one-liner shape as the media
popup's `popup-visible` toggle. `click-right = pavucontrol` is unchanged.

A new one-shot script, `chezmoi/dot_config/eww/scripts/volume-status.sh`,
queries `pactl get-sink-volume @DEFAULT_SINK@` and
`pactl get-sink-mute @DEFAULT_SINK@` and prints one line of JSON:
`{"volume": N, "muted": bool}`. This is polled by an eww `defpoll`
(`:interval "1s" :run-while volume-popup-visible`) — no persistent
process, unlike `mpris-daemon.sh`'s `--follow` stream, since polling only
while the popup is visible is cheap and volume doesn't need real-time
push updates.

The popup itself follows sub-project 1's exact window pattern: a
persistent `defwindow` (`:wm-ignore true`, opened once at `eww daemon`
startup, never closed — the `revealer` inside controls visible/hidden),
anchored `bottom right` (since `pulseaudio` sits further right on the bar
than `nowplaying`, unlike `nowplaying-popup`'s `bottom center`).

## Components

- `chezmoi/dot_config/eww/scripts/volume-status.sh` — one-shot script,
  prints `{"volume": N, "muted": bool}`. Falls back to
  `{"volume": 0, "muted": false}` if `pactl` fails (no default sink).
- `chezmoi/dot_config/eww/eww.yuck` (extended) — adds:
  - `(include "./widgets/volume.yuck")`
  - `(defvar volume-popup-visible false)`
  - `(defpoll volume_json :interval "1s" :initial "{\"volume\": 0, \"muted\": false}" :run-while volume-popup-visible \`~/.config/eww/scripts/volume-status.sh\`)`
  - `(defwindow volume-popup :monitor 0 :geometry (geometry :x "0px" :y "29px" :width "220px" :height "100px" :anchor "bottom right") :stacking "fg" :wm-ignore true (volume :json volume_json :visible volume-popup-visible))`
- `chezmoi/dot_config/eww/eww.scss` (extended) — adds
  `@import "widgets/volume.scss";`.
- `chezmoi/dot_config/eww/widgets/volume.yuck` — `defwidget volume [json
  visible]`: `revealer` wrapping a `scale` (`:value {json.volume} :min 0
  :max 100 :onchange "pactl set-sink-volume @DEFAULT_SINK@ {}%"`) and a
  mute button (`:onclick "pactl set-sink-mute @DEFAULT_SINK@ toggle"`,
  icon swaps on `json.muted`).
- `chezmoi/dot_config/eww/widgets/volume.scss` — styling using the same
  colorice SCSS vars as `nowplaying.scss` ($base, $text, $mauve,
  $surface0, etc).
- `chezmoi/dot_config/polybar/executable_launch.sh` — one more line,
  `eww open volume-popup`, alongside the existing
  `eww open nowplaying-popup`.
- `chezmoi/dot_config/polybar/config.ini` — `[module/pulseaudio]` gets a
  `click-left` toggling `volume-popup-visible`, same shape as
  `nowplaying`'s toggle.

## Data flow

```
polybar pulseaudio click-left → toggle volume-popup-visible
        → revealer transition (animations.scss) → popup shows/hides

volume-popup-visible=true → defpoll starts (1s interval)
        → volume-status.sh → pactl get-sink-volume / get-sink-mute
        → volume_json → scale widget value + mute button icon

scale drag → onchange → pactl set-sink-volume @DEFAULT_SINK@ {}%
mute button click → onclick → pactl set-sink-mute @DEFAULT_SINK@ toggle
```

## Error handling

- No default sink / `pactl` failure: `volume-status.sh` prints the safe
  fallback `{"volume": 0, "muted": false}` instead of erroring or
  producing invalid JSON.
- Popup toggled before `eww daemon` is up: same non-issue as sub-project
  1 — the daemon is already running by the time any user interaction
  happens (started at login via `launch.sh`), no new race to guard.

## Testing

Same manual-only convention as sub-project 1 (no application test suite
in this repo):

1. `bash -n` on `volume-status.sh`.
2. Standalone smoke test: run `volume-status.sh` directly, confirm valid
   JSON output (and the fallback shape if no sink is present).
3. `ansible-playbook ansible/site.yml --syntax-check` (expected no-op —
   this sub-project touches no ansible files).
4. Manual paren/brace balance check on the new yuck/scss (no `eww`
   binary in the dev sandbox, same as sub-project 1 — full `eww
   validate` deferred to a provisioned machine).
5. On a provisioned machine: click `pulseaudio`, confirm popup opens
   with animation, drag slider and confirm volume changes, click mute
   button and confirm icon/state updates, click again to close.
