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
nemo_git_integration_DIR="${HOME_DIR}/.local/share/nemo/nemo-git-integration"
CONFIG_DIR="${HOME_DIR}/.config/nemo/actions"


log() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

require_cmds() {
  for cmd in jq cp rm mkdir sed find; do
    command -v "$cmd" >/dev/null || error "Missing required command: $cmd"
  done
}

install_files() {
  [[ -f "./.config/nemo/actions/actions-tree.json" ]] || error "Integration JSON missing: $INTEGRATION_JSON"

  mkdir -p "$ICONS_DIR"
  mkdir -p "$NEMO_ACTIONS_DIR"
  mkdir -p "$nemo_git_integration_DIR"
  mkdir -p "$CONFIG_DIR"

  cp -r ./icons/* "$ICONS_DIR/"
  cp -r ./nemo/actions/* "$NEMO_ACTIONS_DIR/"
  cp -r ./nemo-git-integration/* "$nemo_git_integration_DIR/"
  cp -r ./.config/nemo/actions/* "$CONFIG_DIR/"

  find "$NEMO_ACTIONS_DIR" -name '*.nemo_action' -exec sed -i "s|__HOME__|$HOME_DIR|g" {} +

  log "Installed Nemo Git Integration files."

  log "Start Installing Nemo Git Status Extension"
  ./nemo-python/extensions/install.sh
  log "Done Installing Nemo Git Status Extension"
}

main() {
  require_cmds
  install_files
  log "Installation complete."
}

main "$@"
