# Eww animation toolkit + media widget (sub-project 1 of 7)

## Context

Part of a larger "eww widgets + transitions/animations library for polybar"
effort, decomposed into sub-projects built one at a time:

1. **Animation toolkit + media popup** (this spec)
2. Volume/quick-settings popup
3. Sysinfo drawer (cpu/mem/gpu/temperature)
4. Tray + powermenu popup
5. Notification center
6. Calendar popup

Polybar stays the bar shell. Each module above keeps a slim icon/label in
polybar; clicking it toggles a floating eww window with richer content near
that spot. No polybar module is fully replaced by eww — eww augments it.

## Goals

- Ship a working eww popup for the `nowplaying` module (art, title, artist,
  album, position, play/pause/prev/next).
- Build a reusable animation layer (durations/easing/transition classes) so
  every later popup imports the same toolkit instead of redefining
  animations per widget.
- Reuse the existing `playerctl --follow` stream (`mpris-daemon.sh`) as the
  single data source for both polybar's label and eww's popup.
- Keep eww themed with the live Catppuccin palette via colorice, same
  mechanism as polybar/i3/rofi.

## Non-goals

- Replacing any polybar module's bar-row content with eww directly.
- The other 6 sub-projects (volume, sysinfo, tray/powermenu, notifications,
  calendar) — future specs.
- Automated testing infrastructure — this repo has none for desktop config;
  verification stays manual.

## Architecture

`eww daemon` starts alongside polybar in
`chezmoi/dot_config/polybar/executable_launch.sh`, so both processes share
one restart cycle.

`mpris-daemon.sh` keeps its existing `playerctl --follow --format ...`
stream but changes its output format to one JSON line per change:

```json
{"status":"Playing","title":"...","artist":"...","album":"...","art":"file:///...","position":"1:23","length":"3:45"}
```

Polybar's `nowplaying` module derives its compact label from this stream as
before (title only, truncated). Eww's `nowplaying-popup` window uses
`deflisten` on the same script's stdout for the rich view — one `playerctl`
process, two consumers, no duplicate polling.

Popup window: anchored bottom-center, positioned just above the polybar bar
(offset-y = bar height, 29px), content wrapped in an eww `revealer` for
open/close animation. Triggered by polybar's `nowplaying` module
`click-left` calling `eww open --toggle nowplaying-popup` (replaces the old
`now-playing-details.sh` notify-send script, which gets deleted).

## Components

- `chezmoi/dot_config/eww/eww.yuck` — top-level config: daemon config,
  `nowplaying-popup` window definition (anchor, geometry, revealer wrapper).
- `chezmoi/dot_config/eww/animations.scss` — shared toolkit: SCSS variables
  (`$transition-fast: 150ms`, `$ease: cubic-bezier(...)`, etc.) plus reusable
  fade/slide transition classes. Every future widget's `.scss` imports this
  file instead of redefining animation values.
- `chezmoi/dot_config/eww/widgets/nowplaying.yuck` +
  `chezmoi/dot_config/eww/widgets/nowplaying.scss` — the widget itself:
  art image, title/artist/album labels, position/length bar, playerctl
  control buttons. Imports `animations.scss`.
- `chezmoi/dot_config/polybar/scripts/executable_mpris-daemon.sh` — updated
  to emit JSON instead of the current pipe-delimited line.
- `chezmoi/dot_config/polybar/config.ini` — `nowplaying` module's
  `click-left` updated to `eww open --toggle nowplaying-popup`.
- `chezmoi/dot_config/polybar/scripts/executable_now-playing-details.sh` —
  deleted (superseded by the popup).
- `chezmoi/dot_config/colorice/templates/eww-colors.scss` — new colorice
  template so `colorice --apply` regenerates eww's palette import alongside
  polybar/i3/rofi's, following the existing per-tool template pattern in
  that directory.
- `ansible/group_vars/all/packages.yml` — add `eww`.

## Data flow

```
playerctl --follow (mpris-daemon.sh)
        │
        ▼ JSON line per change
        ├─→ polybar nowplaying label (title, truncated)
        └─→ eww deflisten var → nowplaying-popup content (live update)

polybar nowplaying click-left → `eww open --toggle nowplaying-popup`
        → revealer transition (animations.scss) → popup shows/hides
```

## Error handling

- `eww open` called before `eww daemon` is up (e.g. race during login):
  fails silently, same as any other unhandled click-handler failure
  elsewhere in the bar today. No new error UX introduced.
- No MPRIS player running: popup renders an idle/empty state rather than
  erroring; matches current polybar behavior of clearing the label.

## Testing

No automated test framework exists for this repo's desktop config, and none
is being added — verification is manual:

1. Play/pause a track via any MPRIS player; confirm polybar label updates.
2. Click the `nowplaying` module; confirm popup opens with animation,
   shows correct art/title/artist/album/position, and updates live.
3. Click again; confirm popup closes with animation.
4. Restart via `launch.sh`; confirm both `polybar` and `eww daemon` come
   back and the popup still works.
5. Run `colorice --apply`; confirm the popup picks up the new palette.
