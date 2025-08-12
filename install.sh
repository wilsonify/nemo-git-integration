#!/usr/bin/env bash
#
# install.sh - Install Nemo Git Integration with submenu support
#
# Usage:
#   ./install.sh              # Normal install
#   ./install.sh uninstall    # Undo installation and restore backup
#   ./install.sh force        # Install, overwriting existing backup
#
set -euo pipefail

HOME_DIR="${HOME}"
ICONS_DIR="${HOME_DIR}/.local/share/icons"
NEMO_DIR="${HOME_DIR}/.local/share/nemo"
GIT_INTEGRATION_DIR="${HOME_DIR}/.local/share/nemo-git-integration"
CONFIG_DIR="${HOME_DIR}/.config/nemo/actions"
LAYOUT_FILE="${CONFIG_DIR}/actions-tree.json"
BACKUP_FILE="${CONFIG_DIR}/actions-tree-bkup.json"
GIT_MENU_FILE="nemo-git-integration/actions-tree.json"

GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }

require_cmd() {
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "Required command '$cmd' not found."
            exit 1
        fi
    done
}

backup_layout() {
    if [[ -f "$LAYOUT_FILE" ]]; then
        if [[ -f "$BACKUP_FILE" && "$1" != "force" ]]; then
            error "Backup already exists at $BACKUP_FILE. Use './install.sh force' to overwrite."
            exit 1
        fi
        cp "$LAYOUT_FILE" "$BACKUP_FILE"
        log "Backup created at $BACKUP_FILE"
    else
        log "No existing Nemo actions layout found, creating empty layout."
        mkdir -p "$CONFIG_DIR"
        echo '{"toplevel":[]}' > "$LAYOUT_FILE"
    fi
}

install_files() {
    log "Copying icons..."
    mkdir -p "$ICONS_DIR"
    cp -r ./icons/* "$ICONS_DIR/"

    log "Copying Nemo actions..."
    mkdir -p "$NEMO_DIR/actions"
    cp -r ./nemo/actions/* "$NEMO_DIR/actions/"

    log "Copying Git integration directory..."
    cp -r ./nemo-git-integration "$GIT_INTEGRATION_DIR"

    log "Replacing __HOME__ placeholders in .nemo_action files..."
    find "$NEMO_DIR" -type f -name "*.nemo_action" \
        -exec sed -i "s|__HOME__|$HOME_DIR|g" {} \;
}

update_layout() {
    if [[ ! -f "$GIT_MENU_FILE" ]]; then
        error "Git menu layout file missing: $GIT_MENU_FILE"
        exit 1
    fi

    log "Updating Nemo actions layout..."

    mkdir -p "$CONFIG_DIR"

    # Use jq to merge submenu JSON safely
    jq --slurpfile gitmenu "$GIT_MENU_FILE" \
       '.toplevel += $gitmenu[0].toplevel' \
       "$LAYOUT_FILE" > "${LAYOUT_FILE}.tmp"

    mv "${LAYOUT_FILE}.tmp" "$LAYOUT_FILE"

    log "Git submenu added to Nemo actions layout."
}

restore_backup() {
    if [[ -f "$BACKUP_FILE" ]]; then
        cp "$BACKUP_FILE" "$LAYOUT_FILE"
        log "Restored Nemo actions layout from backup."
    else
        warn "No backup file found at $BACKUP_FILE. Layout unchanged."
    fi
}

remove_files() {
    log "Removing installed icons..."
    rm -f "$ICONS_DIR"/* || warn "Failed to remove some icons"

    log "Removing installed Nemo actions..."
    rm -f "$NEMO_DIR/actions"/* || warn "Failed to remove some Nemo actions"

    log "Removing Git integration directory..."
    rm -rf "$GIT_INTEGRATION_DIR" || warn "Failed to remove Git integration directory"
}

main() {
    require_cmd jq cp rm mkdir sed find

    case "${1:-}" in
        uninstall)
            remove_files
            restore_backup
            log "Uninstall complete."
            ;;
        force)
            backup_layout "force"
            install_files
            update_layout
            log "Install complete with forced backup overwrite."
            ;;
        "" )
            backup_layout
            install_files
            update_layout
            log "Install complete."
            ;;
        *)
            error "Invalid argument: $1"
            echo "Usage: $0 [uninstall|force]"
            exit 1
            ;;
    esac
}

main "$@"
