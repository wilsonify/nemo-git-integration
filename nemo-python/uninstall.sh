#!/usr/bin/env bash
set -euo pipefail

EXT_NAME="nemo-git-status"
EXT_DIR="$HOME/.local/share/nemo-python/scripts"
SCHEMA_FILE="org.nemo.scripts.nemo-git-status.gschema.xml"
SCHEMA_DIR="/usr/share/glib-2.0/schemas"

log() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

log ">>> Uninstalling Nemo scripts: $EXT_NAME"

log "Remove scripts python file"
if [ -f "$EXT_DIR/$EXT_NAME.py" ]; then
    log "Removing $EXT_DIR/$EXT_NAME.py"
    rm -f "$EXT_DIR/$EXT_NAME.py"
else
    log "scripts file not found in $EXT_DIR (skipping)"
fi

log "Remove schema file (requires sudo)"
if [ -f "$SCHEMA_DIR/$SCHEMA_FILE" ]; then
    log "Removing schema $SCHEMA_FILE from $SCHEMA_DIR"
    sudo rm -f "$SCHEMA_DIR/$SCHEMA_FILE"
    log "Recompiling GSettings schemas"
    sudo glib-compile-schemas "$SCHEMA_DIR"
else
    log "Schema file not found in $SCHEMA_DIR (skipping)"
fi


log "Restarting Nemo..."
nemo -q || true
nohup nemo >/dev/null 2>&1 &

log ">>> Uninstallation complete!"
