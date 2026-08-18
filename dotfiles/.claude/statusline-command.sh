#!/bin/bash
# Claude Code statusline: caveman badge (if active) + model name + live token/cost usage.
# Configured via ~/.claude/settings.json -> statusLine.command
# Replaces manual /cost checks with an always-visible summary.

input=$(cat)

# Preserve existing caveman mode badge (script ignores stdin, safe to call standalone).
CAVEMAN_SCRIPT=$(find "$HOME/.claude/plugins/cache/caveman/caveman" -maxdepth 2 -name caveman-statusline.sh 2>/dev/null | head -1)
caveman_badge=""
if [ -n "$CAVEMAN_SCRIPT" ] && [ -f "$CAVEMAN_SCRIPT" ]; then
  caveman_badge=$(bash "$CAVEMAN_SCRIPT" 2>/dev/null)
fi

model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
used_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

segments=()
[ -n "$model" ] && segments+=("$model")
[ -n "$used_pct" ] && segments+=("$(printf 'ctx %.0f%%' "$used_pct")")
[ -n "$five_pct" ] && segments+=("$(printf '5h %.0f%%' "$five_pct")")
[ -n "$week_pct" ] && segments+=("$(printf '7d %.0f%%' "$week_pct")")

info=""
if [ "${#segments[@]}" -gt 0 ]; then
  info=$(IFS='|'; printf '%s' "${segments[*]}")
  info="${info//|/ | }"
fi

[ -n "$caveman_badge" ] && printf '%s ' "$caveman_badge"
[ -n "$info" ] && printf '\033[2m%s\033[0m' "$info"
printf '\n'
