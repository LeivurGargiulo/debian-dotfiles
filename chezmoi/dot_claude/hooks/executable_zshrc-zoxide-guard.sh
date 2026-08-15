#!/usr/bin/env bash
# PostToolUse guard: keep `eval "$(zoxide init zsh)"` as the last line of ~/.zshrc.
# Root cause of the recurring zoxide "config issue" warning was appends landing after it.
f=$(jq -r '.tool_input.file_path // empty')
[ "$f" = "$HOME/.zshrc" ] || exit 0
[ -f "$f" ] || exit 0

line='eval "$(zoxide init zsh)"'
grep -qF "$line" "$f" || exit 0

last=$(grep -vE '^[[:space:]]*$' "$f" | tail -1)
[ "$last" = "$line" ] && exit 0

tmp=$(mktemp)
grep -vF "$line" "$f" > "$tmp"
printf '\n%s\n' "$line" >> "$tmp"
mv "$tmp" "$f"
echo '{"systemMessage": "zoxide init line was pushed off the end of ~/.zshrc — moved it back to keep zoxide happy."}'
