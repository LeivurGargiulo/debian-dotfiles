#!/usr/bin/env bash
# fastfetch's config.jsonc uses semicolon-separated RGB decimal
# ("171;157;242"), both for `keyColor` fields and embedded ANSI escapes
# (`[38;2;R;G;Bm`) — wallbash's own `<wallbash_..._rgb>` placeholder
# only produces comma-separated ("171,157,242", see color.set.sh's
# rgba_to_rgb()), so this needs a real substitution pass rather than a
# plain <wallbash_...> placeholder. color.set.sh exports every dcol_*
# variable before running this script.
set -euo pipefail

hex_to_semi_rgb() {
    local hex="${1#\#}"
    printf '%d;%d;%d' "$((16#${hex:0:2}))" "$((16#${hex:2:2}))" "$((16#${hex:4:2}))"
}

out="${HOME}/.config/fastfetch/config.jsonc"
mkdir -p "$(dirname "$out")"

key="$(hex_to_semi_rgb "${dcol_2xa7:-ab9df2}")"
accent="$(hex_to_semi_rgb "${dcol_4xa9:-ff6188}")"
label="$(hex_to_semi_rgb "${dcol_3xa7:-78dce8}")"
esc='\u001b'

cat >"$out" <<EOF
{
  "\$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "source": "arch",
    "color": { "1": "white" },
    "padding": { "top": 2, "left": 2, "right": 2 }
  },
  "display": {
    "separator": " ${esc}[38;2;${label}m◆${esc}[0m ",
    "constants": [
      "${esc}[38;2;${accent}m─────────────────${esc}[0m"
    ],
    "key": { "type": "icon", "paddingLeft": 2 }
  },
  "modules": [
    "title",
    "separator",
    { "type": "custom", "format": "${esc}[38;2;${accent}m┌${esc}[0m{\$1} ${esc}[38;2;${label}mHardware Information${esc}[0m {\$1}${esc}[38;2;${accent}m┐${esc}[0m" },
    { "type": "host", "keyColor": "${key}" },
    { "type": "cpu", "keyColor": "${key}" },
    { "type": "gpu", "keyColor": "${key}" },
    { "type": "disk", "keyColor": "${key}" },
    { "type": "memory", "keyColor": "${key}" },
    { "type": "display", "keyColor": "${key}", "format": "{width}x{height} in 27\", {refresh-rate} Hz [{type}]" },
    { "type": "custom", "format": "${esc}[38;2;${accent}m└${esc}[0m{\$1}${esc}[38;2;${accent}m──────────────────${esc}[0m{\$1}${esc}[38;2;${accent}m┘${esc}[0m" },
    { "type": "custom", "format": "" },
    { "type": "custom", "format": "${esc}[38;2;${accent}m┌${esc}[0m{\$1} ${esc}[38;2;${label}mSoftware Information${esc}[0m {\$1}${esc}[38;2;${accent}m┐${esc}[0m" },
    { "type": "os", "keyColor": "${key}" },
    { "type": "kernel", "keyColor": "${key}" },
    { "type": "lm", "keyColor": "${key}" },
    { "type": "wm", "keyColor": "${key}" },
    { "type": "shell", "keyColor": "${key}" },
    { "type": "terminal", "keyColor": "${key}" },
    { "type": "font", "keyColor": "${key}" },
    { "type": "icons", "keyColor": "${key}" },
    { "type": "packages", "keyColor": "${key}" },
    { "type": "uptime", "keyColor": "${key}" },
    { "type": "locale", "keyColor": "${key}" },
    { "type": "custom", "format": "${esc}[38;2;${accent}m└${esc}[0m{\$1}${esc}[38;2;${accent}m──────────────────${esc}[0m{\$1}${esc}[38;2;${accent}m┘${esc}[0m" },
    { "type": "colors" }
  ]
}
EOF
