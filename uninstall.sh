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

require_cmds() {
  for cmd in rm; do
    command -v "$cmd" >/dev/null || error "Missing required command: $cmd"
  done
}

remove_files() {
  rm -f "$ICONS_DIR"/* "$NEMO_ACTIONS_DIR"/* "$LAYOUT_FILE" || true
  log "Removed installed Nemo Git Integration files."
  log "Start uninstalling Nemo Git Status scripts"
  echo "[INFO] >>> Uninstalling Nemo scripts: nemo_git_status"
  rm -f "$HOME/.local/share/nemo-python/extensions/nemo_git_status.py"
  rm -f "$HOME/.local/share/nemo-python/extensions/__pycache__"
  echo "[INFO] Restarting Nemo..."
  nemo -q || true
  nohup nemo >/dev/null 2>&1 &
  echo "[INFO] >>> Uninstallation complete!"
  log "Done uninstalling Nemo Git Status scripts"
}

main() {
  require_cmds
  remove_files
  log "Uninstall complete."
}

main "$@"
