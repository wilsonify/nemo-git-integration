#!/usr/bin/env bash
#
# install.sh - Simple install for Nemo Git Integration submenu
#
# Usage:
#   ./install.sh   # Always overwrite without asking
#

set -euo pipefail

HOME_DIR="${HOME}"
ICONS_DIR="${HOME_DIR}/.local/share/icons"
NEMO_ACTIONS_DIR="${HOME_DIR}/.local/share/nemo/actions"
CONFIG_DIR="${HOME_DIR}/.config/nemo/actions"
LAYOUT_FILE="${CONFIG_DIR}/actions-tree.json"
INTEGRATION_JSON="${HOME_DIR}/.config/nemo/actions/actions-tree.json"

log() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

require_cmds() {
  for cmd in jq cp rm mkdir sed find; do
    command -v "$cmd" >/dev/null || error "Missing required command: $cmd"
  done
}

install_files() {
  [[ -f "$INTEGRATION_JSON" ]] || error "Integration JSON missing: $INTEGRATION_JSON"

  mkdir -p "$ICONS_DIR" "$NEMO_ACTIONS_DIR" "$CONFIG_DIR"

  cp -r ./icons/* "$ICONS_DIR/"
  cp -r ./nemo/actions/* "$NEMO_ACTIONS_DIR/"
  cp "$INTEGRATION_JSON" "$LAYOUT_FILE"

  find "$NEMO_ACTIONS_DIR" -name '*.nemo_action' -exec sed -i "s|__HOME__|$HOME_DIR|g" {} +

  log "Installed Nemo Git Integration files."
}

main() {
  require_cmds
  install_files
  log "Installation complete."
}

main "$@"
