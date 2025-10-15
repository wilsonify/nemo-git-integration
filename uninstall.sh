#!/usr/bin/env bash
#
# uninstall.sh - Simple uninstall for Nemo Git Integration submenu
#
# Usage:
#   ./uninstall.sh   # Always remove installed files without asking
#

set -euo pipefail

HOME_DIR="${HOME}"
ICONS_DIR="${HOME_DIR}/.local/share/icons"
NEMO_ACTIONS_DIR="${HOME_DIR}/.local/share/nemo/actions"
CONFIG_DIR="${HOME_DIR}/.config/nemo/actions"
LAYOUT_FILE="${CONFIG_DIR}/actions-tree.json"

log() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

rm -f "$ICONS_DIR"/* "$NEMO_ACTIONS_DIR"/* "$LAYOUT_FILE" || true
log "Removed installed Nemo Git Integration files."
log "Start uninstalling Nemo Git Status extension"
log "Uninstalling Nemo extension: nemo_git_status"
rm -f "$HOME/.local/share/nemo-python/extensions/nemo_git_status.py"
rm -f "$HOME/.local/share/nemo-python/extensions/__pycache__"
log "Restarting Nemo..."
nemo -q || true
nohup nemo >/dev/null 2>&1 &
log "Uninstallation complete!"
log "Done uninstalling Nemo Git Status extension"
log "Uninstall complete."
