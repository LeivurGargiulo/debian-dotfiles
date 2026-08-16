#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src_root="$repo_root/dotfiles"

find "$src_root" -type f | while IFS= read -r src; do
    rel="${src#"$src_root"/}"
    dest="$HOME/$rel"
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
    echo "linked: ~/$rel"
done
