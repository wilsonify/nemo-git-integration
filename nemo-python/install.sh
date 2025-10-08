#!/usr/bin/env bash
set -euo pipefail

EXT_NAME='nemo_git_status'
EXT_DIR="$HOME/.local/share/nemo-python/extensions"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/extensions" && pwd)"

echo "[INFO] Installing $EXT_NAME to $EXT_DIR"
mkdir -p "$EXT_DIR"
cp "$SRC_DIR/$EXT_NAME.py" "$EXT_DIR/"

echo "[INFO] Restarting Nemo..."
nemo -q || true
nohup nemo >/dev/null 2>&1 &

echo "[INFO] Installation complete!"
echo "[INFO] Manage extensions in Nemo: Edit -> Plugins"