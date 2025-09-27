#!/usr/bin/env bash
set -euo pipefail

EXT_NAME="nemo-git-status"
EXT_DIR="$HOME/.local/share/nemo-python/extensions"
SCHEMA_SRC="org.nemo.extensions.nemo-file-checker.gschema.xml"
SCHEMA_DIR="/usr/share/glib-2.0/schemas"

echo ">>> Installing Nemo extension: $EXT_NAME"

# Ensure extension directory exists
mkdir -p "$EXT_DIR"

# Copy extension python file
if [[ -f "$EXT_NAME.py" ]]; then
    echo " - Copying $EXT_NAME.py to $EXT_DIR/"
    cp "$EXT_NAME.py" "$EXT_DIR/"
else
    echo "ERROR: $EXT_NAME.py not found in current directory!"
    exit 1
fi

# Copy schema (needs root)
if [[ -f "$SCHEMA_SRC" ]]; then
    echo " - Installing schema to $SCHEMA_DIR (requires sudo)"
    sudo cp "$SCHEMA_SRC" "$SCHEMA_DIR/"
    echo " - Compiling GSettings schemas"
    sudo glib-compile-schemas "$SCHEMA_DIR"
else
    echo "WARNING: $SCHEMA_SRC not found, skipping schema install."
fi

# Restart Nemo
echo " - Restarting Nemo..."
nemo -q || true
nohup nemo >/dev/null 2>&1 &

echo ">>> Installation complete!"
echo "You can manage extensions in Nemo via:"
echo "  Edit -> Plugins"
