#!/usr/bin/env bash
# Pull SSH private keys out of Bitwarden as file attachments.
# Requires: bw CLI (npm @bitwarden/cli), already `bw login && bw unlock`.
set -e

if ! command -v bw &>/dev/null; then
    echo "bw CLI not found (npm i -g @bitwarden/cli)" >&2
    exit 1
fi

read -rp "Bitwarden item id holding the SSH keys: " item_id
read -rp "Attachment name for the key to pull (e.g. id_ed25519): " attachment

mkdir -p ~/.ssh
bw get attachment "$attachment" --itemid "$item_id" --output "$HOME/.ssh/$attachment"
chmod 600 "$HOME/.ssh/$attachment"
echo "Wrote ~/.ssh/$attachment"
