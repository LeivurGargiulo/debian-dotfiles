# Monokai Pro palette

Source: `loctvl842/monokai-pro.nvim` palette definitions, cross-checked
against monokai.pro's published editor screenshots. This is the single
source of truth for every Monokai-Pro-themed config file in this repo —
copy from here, don't re-derive.

| Role | Hex |
|---|---|
| Background | `#2d2a2e` |
| Background (darker, panels/statuslines) | `#221f22` |
| Selection / line-highlight | `#403e41` |
| Foreground / text | `#fcfcfa` |
| Dimmed gray (comments, muted text) | `#939293` |
| Pink / red (errors, keywords, deletions) | `#ff6188` |
| Orange (numbers, constants, warnings) | `#fc9867` |
| Yellow (strings, warnings) | `#ffd866` |
| Green (success, additions, strings) | `#a9dc76` |
| Cyan (info, types, paths) | `#78dce8` |
| Purple (functions, accents) | `#ab9df2` |

## Tools without hex support

Some tools in this repo's theming pass can't take hex directly and use an
approximation instead — documented per-tool in the config file itself, but
summarized here:

- **cmus** — 256-color terminal palette (nearest xterm256 index per hex,
  6x6x6 cube + grayscale ramp math).
- **taskwarrior** — `rgbRGB` cube notation (digits 0-5) + `grayN` ramp,
  same underlying 256-color math as cmus.
- **calcurse** — only 8 ANSI names + `default`, one global `fg on bg` pair
  for the whole UI (calcurse has no per-element theming at all).
- **newsboat** — only named ANSI colors or `colorN` (256-palette index) in
  its own config; true hex fidelity requires remapping the *terminal's*
  256-color palette slots to these hex values (e.g. in kitty.conf), which
  the HyDE/wallbash layer (Task 2) already does for the primary palette
  slots — newsboat's `colorN` references then resolve to the right hex via
  the terminal, not via newsboat itself.
