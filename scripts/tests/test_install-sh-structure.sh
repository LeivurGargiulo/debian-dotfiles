#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

bash -n "$repo_root/install.sh"
echo "syntax OK"

for f in packages/pacman.txt packages/aur.txt vendor/hyde/Scripts/install.sh \
    scripts/symlink-dotfiles.sh; do
    if [[ ! -f "$repo_root/$f" ]]; then
        echo "FAIL: install.sh depends on missing file: $f" >&2
        exit 1
    fi
    if ! grep -q "$f" "$repo_root/install.sh" && ! grep -q "$(basename "$f")" "$repo_root/install.sh"; then
        echo "FAIL: install.sh never references $f" >&2
        exit 1
    fi
done

echo "PASS"
