#!/usr/bin/env bash
set -euo pipefail

# Resolve this script's directory (absolute path)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXT_NAME="nemo-git-status"
EXT_DIR="$HOME/.local/share/nemo-python/extensions"
SCHEMA_SRC="$SCRIPT_DIR/org.nemo.extensions.nemo-git-status.gschema.xml"
SCHEMA_DIR="/usr/share/glib-2.0/schemas"

log() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

log ">>> Installing Nemo extension: $EXT_NAME"

log "Ensure extension directory exists"
mkdir -p "$EXT_DIR"

log "Copy extension python file"
log " - Copying $EXT_NAME.py to $EXT_DIR/"
cp "$SCRIPT_DIR/$EXT_NAME.py" "$EXT_DIR/"

# Copy schema (needs root)
log " - Installing schema to $SCHEMA_DIR (requires sudo)"
sudo cp "$SCHEMA_SRC" "$SCHEMA_DIR/"

log " - Compiling GSettings schemas"
sudo glib-compile-schemas "$SCHEMA_DIR"

log "Restart Nemo"
log " - Restarting Nemo..."
nemo -q || true
nohup nemo >/dev/null 2>&1 &

log ">>> Installation complete!"
log "You can manage extensions in Nemo via:"
log "  Edit -> Plugins"
