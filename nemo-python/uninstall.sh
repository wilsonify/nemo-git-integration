set -euo pipefail

EXT_NAME="nemo_git_status"
EXT_DIR="$HOME/.local/share/nemo-python/extensions"

echo "[INFO] >>> Uninstalling Nemo scripts: $EXT_NAME"

SCRIPT="$EXT_DIR/$EXT_NAME.py"
if [ -f "$SCRIPT" ]; then
    echo "[INFO] Removing $SCRIPT"
    rm -f "$SCRIPT"
else
    echo "[INFO] scripts file not found in $EXT_DIR (skipping)"
fi

echo "[INFO] Restarting Nemo..."
nemo -q || true
nohup nemo >/dev/null 2>&1 &

echo "[INFO] >>> Uninstallation complete!"