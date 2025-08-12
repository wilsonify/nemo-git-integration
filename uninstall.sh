#!/usr/bin/env bash
#
# uninstall.sh — Undo install.sh changes for Nemo Git Integration
#
set -euo pipefail
IFS=$'\n\t'

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HOME_DIR="${HOME}"
CONFIG_DIR="${HOME_DIR}/.config/nemo/actions"
TARGET_ICONS_DIR="${HOME_DIR}/.local/share/icons"
TARGET_NEMO_ACTIONS_DIR="${HOME_DIR}/.local/share/nemo/actions"
GIT_INTEGRATION_DIR="${HOME_DIR}/.local/share/nemo-git-integration"

LAYOUT_FILE="${CONFIG_DIR}/actions-tree.json"
BACKUP_FILE="${CONFIG_DIR}/actions-tree-bkup.json"

log() { printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"; }
warn() { printf '[%s] WARN: %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*" >&2; }
fail() { log "ERROR: $*" >&2; exit 1; }

log "Starting uninstallation..."

if [[ -f "$BACKUP_FILE" ]]; then
    log "Restoring original actions-tree.json from backup..."
    cp -f "$BACKUP_FILE" "$LAYOUT_FILE" || fail "Failed to restore $LAYOUT_FILE from $BACKUP_FILE"

    if ! cmp -s "$BACKUP_FILE" "$LAYOUT_FILE"; then
        fail "Verification failed — restored file differs from backup."
    fi
    log "Restoration verified."

    log "Removing backup file..."
    rm -f "$BACKUP_FILE" || fail "Failed to remove backup file."
else
    warn "Backup file not found: $BACKUP_FILE. Skipping restoration step."
fi

# Remove installed icons
if [[ -d "$TARGET_ICONS_DIR" ]]; then
    log "Removing installed icons..."
    for file in "$BASE_DIR"/icons/*; do
        target_file="$TARGET_ICONS_DIR/$(basename "$file")"
        if [[ -f "$target_file" ]]; then
            rm -f "$target_file" || fail "Failed to remove $target_file"
            log "Removed $target_file"
        fi
    done
fi

# Remove installed nemo actions
if [[ -d "$TARGET_NEMO_ACTIONS_DIR" ]]; then
    log "Removing installed Nemo actions..."
    for file in "$BASE_DIR"/nemo/actions/*; do
        target_file="$TARGET_NEMO_ACTIONS_DIR/$(basename "$file")"
        if [[ -f "$target_file" ]]; then
            rm -f "$target_file" || fail "Failed to remove $target_file"
            log "Removed $target_file"
        fi
    done
fi

# Remove Git integration folder
if [[ -d "$GIT_INTEGRATION_DIR" ]]; then
    log "Removing Git integration directory..."
    rm -rf "$GIT_INTEGRATION_DIR" || fail "Failed to remove $GIT_INTEGRATION_DIR"
fi

log "Uninstallation complete."
