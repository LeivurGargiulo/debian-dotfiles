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
