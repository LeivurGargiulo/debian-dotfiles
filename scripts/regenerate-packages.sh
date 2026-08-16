#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pacman -Qqm | sort > "$repo_root/packages/aur.txt"
comm -23 <(pacman -Qqe | sort) <(pacman -Qqm | sort) > "$repo_root/packages/pacman.txt"

echo "regenerated packages/pacman.txt and packages/aur.txt from the live system"
echo "review the diff (category # comments from the hand-curated version are gone), then commit"
