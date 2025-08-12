#!/usr/bin/env bash
#
# install.sh - Install Nemo Git Integration submenu
#
# Usage:
#   ./install.sh          # Normal install
#   ./install.sh uninstall # Uninstall and restore backup
#   ./install.sh force    # Install, overwrite backup
#
set -euo pipefail

HOME_DIR="${HOME}"
ICONS_DIR="${HOME_DIR}/.local/share/icons"
NEMO_ACTIONS_DIR="${HOME_DIR}/.local/share/nemo/actions"
CONFIG_DIR="${HOME_DIR}/.config/nemo/actions"
LAYOUT_FILE="${CONFIG_DIR}/actions-tree.json"
BACKUP_FILE="${CONFIG_DIR}/actions-tree-bkup.json"
INTEGRATION_JSON="nemo-git-integration/actions-tree.json"

log()   { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

require_cmd() {
  for cmd; do
    command -v "$cmd" >/dev/null || error "Missing required command: $cmd"
  done
}

backup_layout() {
  mkdir -p "$CONFIG_DIR"
  if [[ -f "$LAYOUT_FILE" && -f "$BACKUP_FILE" && "${1:-}" != "force" ]]; then
    error "Backup exists. Use './install.sh force' to overwrite."
  fi
  cp "${LAYOUT_FILE:-/dev/null}" "$BACKUP_FILE" 2>/dev/null || echo '{"toplevel":[]}' > "$LAYOUT_FILE" && cp "$LAYOUT_FILE" "$BACKUP_FILE"
  log "Backup created at $BACKUP_FILE"
}

install_files() {
  mkdir -p "$ICONS_DIR" "$NEMO_ACTIONS_DIR"
  cp -r ./icons/* "$ICONS_DIR/"
  cp -r ./nemo/actions/* "$NEMO_ACTIONS_DIR/"
  mkdir -p "$CONFIG_DIR"
  cp "$INTEGRATION_JSON" "$LAYOUT_FILE"

  find "$NEMO_ACTIONS_DIR" -name '*.nemo_action' -exec sed -i "s|__HOME__|$HOME_DIR|g" {} +
}

update_layout() {
  jq --slurpfile gitmenu "$LAYOUT_FILE" \
    '.toplevel += $gitmenu[0].toplevel' "$BACKUP_FILE" > "${LAYOUT_FILE}.tmp"
  mv "${LAYOUT_FILE}.tmp" "$LAYOUT_FILE"
  log "Updated actions-tree.json with Git submenu."
}

restore_backup() {
  if [[ -f "$BACKUP_FILE" ]]; then
    cp "$BACKUP_FILE" "$LAYOUT_FILE"
    log "Restored backup layout."
  else
    error "Backup file missing. Cannot restore."
  fi
}

remove_files() {
  rm -f "$ICONS_DIR"/* "$NEMO_ACTIONS_DIR"/* "$LAYOUT_FILE" || true
  log "Removed installed files."
}

main() {
  require_cmd jq cp rm mkdir sed find

  case "${1:-}" in
    uninstall)
      remove_files
      restore_backup
      ;;
    force)
      backup_layout force
      install_files
      update_layout
      ;;
    "")
      backup_layout
      install_files
      update_layout
      ;;
    *)
      error "Invalid argument: $1. Usage: $0 [uninstall|force]"
      ;;
  esac

  log "Operation complete."
}

main "$@"
