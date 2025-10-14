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

# formats arguments as info, error
# >&2 redirects the output to stderr so that calling processes/tools can detect errors.
# exit 1 stops the script immediately with failure status.
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

  log "Start Installing Nemo Git Status scripts"

  EXT_DIR="$HOME/.local/share/nemo-python/extensions"
  echo "[INFO] Installing nemo_git_status to $EXT_DIR"
  mkdir -p "$EXT_DIR"
  cp "./nemo-python/extensions/nemo_git_status.py" "$EXT_DIR/"

  echo "[INFO] Restarting Nemo..."
  nemo -q || true
  nohup nemo >/dev/null 2>&1 &
  echo "[INFO] Installation complete!"
  echo "[INFO] Manage extensions in Nemo: Edit -> Plugins"
  log "Done Installing Nemo Git Status scripts"
}

main() {
  require_cmds
  install_files
  log "Installation complete."
}

main "$@"
