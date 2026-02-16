#!/usr/bin/env bash
#
# cleanup-all.sh - Comprehensive cleanup for nemo-git-integration
#
# Usage:
#   ./cleanup-all.sh              # Clean user-local installation
#   sudo ./cleanup-all.sh --system # Clean system-wide installation
#   ./cleanup-all.sh --all         # Clean both (requires sudo for system)
#
# This script is idempotent and safe to run multiple times.
# It removes all nemo-git-integration files, clears caches, and restarts Nemo.
#

set -euo pipefail

# Default mode
MODE="user"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --system)
            MODE="system"
            shift
            ;;
        --all)
            MODE="all"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--system|--all]"
            echo "  (no args)  Clean user-local installation"
            echo "  --system   Clean system-wide installation (requires sudo)"
            echo "  --all      Clean both user-local and system-wide"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Clean user-local installation
cleanup_user() {
    log_info "Cleaning user-local installation..."
    
    local HOME_DIR="${HOME}"
    local removed_count=0
    
    # Remove .nemo_action files
    local action_files=(
        "git01a-init.nemo_action" "git01b-clone.nemo_action" "git01c-branch.nemo_action"
        "git02a-status.nemo_action" "git02c-log.nemo_action" "git02d-fetch.nemo_action"
        "git03a-pull.nemo_action" "git03b-add.nemo_action" "git03c-commit.nemo_action"
        "git03d-push.nemo_action" "git04a-reset.nemo_action" "git04b-uninit.nemo_action"
        "git04c-unclone.nemo_action" "git04e-unpull.nemo_action" "git04f-unadd.nemo_action"
        "git04g-uncommit.nemo_action" "git04h-unpush.nemo_action"
    )
    
    for action in "${action_files[@]}"; do
        if [ -f "$HOME_DIR/.local/share/nemo/actions/$action" ]; then
            rm -f "$HOME_DIR/.local/share/nemo/actions/$action"
            removed_count=$((removed_count + 1))
        fi
    done
    
    # Remove script directory
    if [ -d "$HOME_DIR/.local/share/nemo/nemo-git-integration" ]; then
        rm -rf "$HOME_DIR/.local/share/nemo/nemo-git-integration"
        removed_count=$((removed_count + 1))
        log_info "Removed user scripts directory"
    fi
    
    # Remove Python extension
    if [ -f "$HOME_DIR/.local/share/nemo-python/extensions/nemo_git_status.py" ]; then
        rm -f "$HOME_DIR/.local/share/nemo-python/extensions/nemo_git_status.py"
        removed_count=$((removed_count + 1))
    fi
    
    if [ -d "$HOME_DIR/.local/share/nemo-python/extensions/__pycache__" ]; then
        rm -rf "$HOME_DIR/.local/share/nemo-python/extensions/__pycache__"
        removed_count=$((removed_count + 1))
    fi
    
    # Remove config file
    if [ -f "$HOME_DIR/.config/nemo/actions/actions-tree.json" ]; then
        rm -f "$HOME_DIR/.config/nemo/actions/actions-tree.json"
        removed_count=$((removed_count + 1))
    fi
    
    # Remove icon files
    local icon_files=(
        "add-file.png" "construction.png" "create.png"
        "happy-file.png" "important-file.png" "winking-file.png"
    )
    
    for icon in "${icon_files[@]}"; do
        if [ -f "$HOME_DIR/.local/share/icons/$icon" ]; then
            rm -f "$HOME_DIR/.local/share/icons/$icon"
            removed_count=$((removed_count + 1))
        fi
    done
    
    # Clear Nemo cache
    if [ -d "$HOME_DIR/.cache/nemo" ]; then
        rm -rf "$HOME_DIR/.cache/nemo"
        log_info "Cleared Nemo cache"
        removed_count=$((removed_count + 1))
    fi
    
    log_info "User cleanup: removed $removed_count items"
}

# Clean system-wide installation
cleanup_system() {
    log_info "Cleaning system-wide installation..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "System cleanup requires root privileges."
        log_error "Please run: sudo $0 --system"
        exit 1
    fi
    
    local removed_count=0
    
    # Remove .nemo_action files
    local action_files=(
        "git01a-init.nemo_action" "git01b-clone.nemo_action" "git01c-branch.nemo_action"
        "git02a-status.nemo_action" "git02c-log.nemo_action" "git02d-fetch.nemo_action"
        "git03a-pull.nemo_action" "git03b-add.nemo_action" "git03c-commit.nemo_action"
        "git03d-push.nemo_action" "git04a-reset.nemo_action" "git04b-uninit.nemo_action"
        "git04c-unclone.nemo_action" "git04e-unpull.nemo_action" "git04f-unadd.nemo_action"
        "git04g-uncommit.nemo_action" "git04h-unpush.nemo_action"
    )
    
    for action in "${action_files[@]}"; do
        if [ -f "/usr/share/nemo/actions/$action" ]; then
            rm -f "/usr/share/nemo/actions/$action"
            removed_count=$((removed_count + 1))
        fi
    done
    
    # Remove script directory
    if [ -d "/usr/share/nemo-git-integration" ]; then
        rm -rf /usr/share/nemo-git-integration
        removed_count=$((removed_count + 1))
        log_info "Removed system scripts directory"
    fi
    
    # Remove Python extension
    if [ -f "/usr/share/nemo-python/extensions/nemo_git_status.py" ]; then
        rm -f /usr/share/nemo-python/extensions/nemo_git_status.py
        removed_count=$((removed_count + 1))
    fi
    
    if [ -d "/usr/share/nemo-python/extensions/__pycache__" ]; then
        rm -rf /usr/share/nemo-python/extensions/__pycache__
        removed_count=$((removed_count + 1))
    fi
    
    # Remove config file
    if [ -f "/etc/xdg/nemo/actions/actions-tree.json" ]; then
        rm -f /etc/xdg/nemo/actions/actions-tree.json
        removed_count=$((removed_count + 1))
    fi
    
    # Remove icon files
    local icon_files=(
        "add-file.png" "construction.png" "create.png"
        "happy-file.png" "important-file.png" "winking-file.png"
    )
    
    for icon in "${icon_files[@]}"; do
        if [ -f "/usr/share/icons/hicolor/scalable/apps/$icon" ]; then
            rm -f "/usr/share/icons/hicolor/scalable/apps/$icon"
            removed_count=$((removed_count + 1))
        fi
    done
    
    # Update icon cache
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
        log_info "Updated system icon cache"
    fi
    
    # Clear user caches for all logged-in users
    if command -v who >/dev/null 2>&1; then
        who | awk '{print $1}' | sort -u | while read -r user; do
            user_home=$(getent passwd "$user" 2>/dev/null | cut -d: -f6)
            if [ -n "$user_home" ] && [ -d "$user_home/.cache/nemo" ]; then
                rm -rf "$user_home/.cache/nemo"
                log_info "Cleared Nemo cache for user: $user"
            fi
        done
    fi
    
    log_info "System cleanup: removed $removed_count items"
}

# Restart Nemo for current user
restart_nemo() {
    log_info "Restarting Nemo..."
    
    # Quit Nemo
    nemo -q 2>/dev/null || true
    sleep 2
    
    # Restart Nemo in background
    if [ -n "${DISPLAY:-}" ]; then
        nohup nemo >/dev/null 2>&1 &
        log_info "Nemo restarted"
    else
        log_warn "No display available, Nemo not restarted"
    fi
}

# Main cleanup process
main() {
    echo "=========================================="
    echo "Nemo Git Integration - Comprehensive Cleanup"
    echo "=========================================="
    echo ""
    
    case "$MODE" in
        user)
            cleanup_user
            restart_nemo
            ;;
        system)
            cleanup_system
            # Try to restart Nemo for the user who invoked sudo
            if [ -n "${SUDO_USER:-}" ]; then
                log_info "Attempting to restart Nemo for user: $SUDO_USER"
                # Preserve the user's DISPLAY environment variable
                SUDO_USER_DISPLAY=$(su - "$SUDO_USER" -c 'echo $DISPLAY' 2>/dev/null || echo ":0")
                su - "$SUDO_USER" -c "nemo -q 2>/dev/null || true; sleep 2; DISPLAY=${SUDO_USER_DISPLAY} nohup nemo >/dev/null 2>&1 &" || true
            fi
            ;;
        all)
            cleanup_user
            cleanup_system
            restart_nemo
            ;;
    esac
    
    echo ""
    echo "=========================================="
    echo "Cleanup Complete!"
    echo "=========================================="
    echo ""
    log_info "To verify complete removal, run: ./verify-removal.sh"
    echo ""
    log_info "If Git menu items still appear:"
    log_info "  1. Log out and log back in"
    log_info "  2. Or run: nemo -q && sleep 2 && nemo &"
    echo ""
}

main "$@"