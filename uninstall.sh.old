#!/usr/bin/env bash
#
# uninstall.sh - Uninstall Nemo Git Integration from user's home directory
#
# Usage:
#   ./uninstall.sh   # Remove all nemo-git-integration files from user installation
#
# This script removes:
#   - .nemo_action files
#   - Shell scripts
#   - Python extensions
#   - Configuration files
#   - Icon files (only those installed by this package)
#   - Nemo caches
#

set -euo pipefail

HOME_DIR="${HOME}"
ICONS_DIR="${HOME_DIR}/.local/share/icons"
NEMO_ACTIONS_DIR="${HOME_DIR}/.local/share/nemo/actions"
NEMO_GIT_DIR="${HOME_DIR}/.local/share/nemo/nemo-git-integration"
CONFIG_DIR="${HOME_DIR}/.config/nemo/actions"
LAYOUT_FILE="${CONFIG_DIR}/actions-tree.json"
PYTHON_EXT_DIR="${HOME_DIR}/.local/share/nemo-python/extensions"
NEMO_CACHE_DIR="${HOME_DIR}/.cache/nemo"

log() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }
error() { echo "[ERROR] $*" >&2; exit 1; }

# Remove .nemo_action files (only those from this package)
remove_action_files() {
    log "Removing .nemo_action files..."
    local action_files=(
        "git01a-init.nemo_action"
        "git01b-clone.nemo_action"
        "git01c-branch.nemo_action"
        "git02a-status.nemo_action"
        "git02c-log.nemo_action"
        "git02d-fetch.nemo_action"
        "git03a-pull.nemo_action"
        "git03b-add.nemo_action"
        "git03c-commit.nemo_action"
        "git03d-push.nemo_action"
        "git04a-reset.nemo_action"
        "git04b-uninit.nemo_action"
        "git04c-unclone.nemo_action"
        "git04e-unpull.nemo_action"
        "git04f-unadd.nemo_action"
        "git04g-uncommit.nemo_action"
        "git04h-unpush.nemo_action"
    )
    
    for action in "${action_files[@]}"; do
        rm -f "$NEMO_ACTIONS_DIR/$action" 2>/dev/null || true
    done
    
    log "Action files removed."
}

# Remove shell scripts directory
remove_script_directory() {
    log "Removing nemo-git-integration scripts directory..."
    if [ -d "$NEMO_GIT_DIR" ]; then
        rm -rf "$NEMO_GIT_DIR"
        log "Scripts directory removed."
    else
        log "Scripts directory not found (already removed or never installed)."
    fi
}

# Remove Python extension
remove_python_extension() {
    log "Removing Nemo Git Status Python extension..."
    rm -f "$PYTHON_EXT_DIR/nemo_git_status.py" 2>/dev/null || true
    rm -rf "$PYTHON_EXT_DIR/__pycache__" 2>/dev/null || true
    log "Python extension removed."
}

# Remove configuration file
remove_config_file() {
    log "Removing configuration file..."
    rm -f "$LAYOUT_FILE" 2>/dev/null || true
    log "Configuration file removed."
}

# Remove icon files (only those installed by this package)
remove_icon_files() {
    log "Removing icon files..."
    local icon_files=(
        "add-file.png"
        "construction.png"
        "create.png"
        "happy-file.png"
        "important-file.png"
        "winking-file.png"
    )
    
    for icon in "${icon_files[@]}"; do
        rm -f "$ICONS_DIR/$icon" 2>/dev/null || true
    done
    
    log "Icon files removed."
}

# Clear Nemo cache to force reload
clear_nemo_cache() {
    log "Clearing Nemo cache..."
    if [ -d "$NEMO_CACHE_DIR" ]; then
        rm -rf "$NEMO_CACHE_DIR"
        log "Nemo cache cleared."
    else
        log "Nemo cache directory not found."
    fi
}

# Restart Nemo
restart_nemo() {
    log "Restarting Nemo..."
    nemo -q 2>/dev/null || true
    sleep 1
    # Start Nemo in background, suppress output
    nohup nemo >/dev/null 2>&1 &
    log "Nemo restarted."
}

# Main uninstall process
main() {
    log "Starting nemo-git-integration uninstall..."
    
    remove_action_files
    remove_script_directory
    remove_python_extension
    remove_config_file
    remove_icon_files
    clear_nemo_cache
    restart_nemo
    
    log "=========================================="
    log "Uninstall complete!"
    log "=========================================="
    log ""
    log "If Git menu items still appear in Nemo:"
    log "  1. Completely quit Nemo: nemo -q"
    log "  2. Wait a few seconds"
    log "  3. Restart Nemo or log out and log back in"
    log "  4. Run: rm -rf ~/.cache/nemo"
    log ""
}

main "$@"
