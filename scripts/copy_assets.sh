#!/usr/bin/env bash
set -euo pipefail

# Copies Flutter assets into web/public/assets if they exist.
# Run from repo root: ./scripts/copy_assets.sh

SRC_DIR="$(pwd)/assets"
DEST_DIR="$(pwd)/web/public/assets"

if [ ! -d "$SRC_DIR" ]; then
  echo "Source assets directory not found: $SRC_DIR"
  exit 0
fi

mkdir -p "$DEST_DIR"
rsync -av --exclude='*.psd' "$SRC_DIR/" "$DEST_DIR/"
echo "Copied assets from $SRC_DIR to $DEST_DIR"


