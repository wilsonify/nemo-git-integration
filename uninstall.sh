#!/usr/bin/env bash
#
# uninstall.sh - Comprehensive uninstall for Nemo Git Integration
#
# Usage:
#   ./uninstall.sh              # Remove user-local installation (default)
#   ./uninstall.sh --system     # Remove system-wide installation (requires sudo)
#   ./uninstall.sh --all        # Remove both user-local and system-wide
#   ./uninstall.sh --verify     # Verify complete removal
#   ./uninstall.sh --help       # Show help message
#
# This script removes:
#   - .nemo_action files
#   - Shell scripts
#   - Python extensions
#   - Configuration files
#   - Icon files (only those installed by this package)
#   - Nemo caches
#

# Note: We use 'set -uo pipefail' without 'set -e' for verify mode
# to allow continuing checks even if individual checks fail
set -uo pipefail

# Default mode
MODE="user"
VERIFY_MODE=false

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
        --verify)
            VERIFY_MODE=true
            shift
            ;;
        --help|-h)
            cat << 'EOF'
Usage: ./uninstall.sh [OPTIONS]

Options:
  (no args)   Remove user-local installation (default)
  --system    Remove system-wide installation (requires sudo)
  --all       Remove both user-local and system-wide installations
  --verify    Verify complete removal without uninstalling
  --help, -h  Show this help message

Examples:
  ./uninstall.sh              # Uninstall from user's home directory
  sudo ./uninstall.sh --system # Uninstall system-wide files
  ./uninstall.sh --all        # Uninstall everything
  ./uninstall.sh --verify     # Check if all files are removed

EOF
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

# Action files list
ACTION_FILES=(
    "git01a-init.nemo_action" "git01b-clone.nemo_action" "git01c-branch.nemo_action"
    "git02a-status.nemo_action" "git02c-log.nemo_action" "git02d-fetch.nemo_action"
    "git03a-pull.nemo_action" "git03b-add.nemo_action" "git03c-commit.nemo_action"
    "git03d-push.nemo_action" "git04a-reset.nemo_action" "git04b-uninit.nemo_action"
    "git04c-unclone.nemo_action" "git04e-unpull.nemo_action" "git04f-unadd.nemo_action"
    "git04g-uncommit.nemo_action" "git04h-unpush.nemo_action"
)

# Icon files list
ICON_FILES=(
    "add-file.png" "construction.png" "create.png"
    "happy-file.png" "important-file.png" "winking-file.png"
)

# Remove user-local installation
remove_user_local() {
    log_info "Removing user-local installation..."
    
    local HOME_DIR="${HOME}"
    local removed_count=0
    
    # Remove .nemo_action files
    for action in "${ACTION_FILES[@]}"; do
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
    for icon in "${ICON_FILES[@]}"; do
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
    
    log_info "User-local cleanup: removed $removed_count items"
}

# Remove system-wide installation
remove_system_wide() {
    log_info "Removing system-wide installation..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "System cleanup requires root privileges."
        log_error "Please run: sudo $0 --system"
        exit 1
    fi
    
    local removed_count=0
    
    # Remove .nemo_action files
    for action in "${ACTION_FILES[@]}"; do
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
    for icon in "${ICON_FILES[@]}"; do
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
            # Validate username: only allow alphanumeric, underscore, hyphen
            if ! echo "$user" | grep -qE '^[a-zA-Z0-9_-]+$'; then
                log_warn "Skipping invalid username: $user"
                continue
            fi
            
            user_home=$(getent passwd "$user" 2>/dev/null | cut -d: -f6)
            if [ -n "$user_home" ] && [ -d "$user_home/.cache/nemo" ]; then
                rm -rf "$user_home/.cache/nemo"
                log_info "Cleared Nemo cache for user: $user"
            fi
        done
    fi
    
    log_info "System-wide cleanup: removed $removed_count items"
}

# Restart Nemo
restart_nemo() {
    # Skip Nemo restart in non-interactive/CI environments
    if [ -z "${DISPLAY:-}" ] || [ ! -t 0 ] || [ -n "${DEBIAN_FRONTEND:-}" ]; then
        log_info "Skipping Nemo restart (non-interactive environment)"
        return 0
    fi
    
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

# Verification functions
found_files=0
total_checks=0

check_file() {
    local file="$1"
    local description="${2:-$file}"
    total_checks=$((total_checks + 1))
    
    if [ -e "$file" ]; then
        log_error "Found: $description"
        found_files=$((found_files + 1))
        return 1
    else
        return 0
    fi
}

check_directory() {
    local dir="$1"
    local description="${2:-$dir}"
    total_checks=$((total_checks + 1))
    
    if [ -d "$dir" ]; then
        log_error "Found: $description"
        found_files=$((found_files + 1))
        return 1
    else
        return 0
    fi
}

verify_system_wide() {
    log_info "Checking system-wide installation locations..."
    
    for action in "${ACTION_FILES[@]}"; do
        check_file "/usr/share/nemo/actions/$action" "System action: $action"
    done
    
    check_directory "/usr/share/nemo-git-integration" "System scripts directory"
    check_file "/usr/share/nemo-python/extensions/nemo_git_status.py" "System Python extension"
    check_file "/etc/xdg/nemo/actions/actions-tree.json" "System config file"
    
    for icon in "${ICON_FILES[@]}"; do
        check_file "/usr/share/icons/hicolor/scalable/apps/$icon" "System icon: $icon"
    done
}

verify_user_local() {
    log_info "Checking user-local installation locations..."
    
    local HOME_DIR="${HOME}"
    
    for action in "${ACTION_FILES[@]}"; do
        check_file "$HOME_DIR/.local/share/nemo/actions/$action" "User action: $action"
    done
    
    check_directory "$HOME_DIR/.local/share/nemo/nemo-git-integration" "User scripts directory"
    check_file "$HOME_DIR/.local/share/nemo-python/extensions/nemo_git_status.py" "User Python extension"
    check_file "$HOME_DIR/.config/nemo/actions/actions-tree.json" "User config file"
    
    for icon in "${ICON_FILES[@]}"; do
        check_file "$HOME_DIR/.local/share/icons/$icon" "User icon: $icon"
    done
}

check_nemo_running() {
    log_info "Checking for running Nemo processes..."
    
    if pgrep -x nemo >/dev/null; then
        log_warn "Nemo is still running. For complete cleanup, restart Nemo."
        log_warn "  Run: nemo -q && sleep 2 && nemo &"
    else
        log_info "No Nemo processes found."
    fi
}

display_verification_summary() {
    echo ""
    echo "=========================================="
    echo "Verification Summary"
    echo "=========================================="
    echo "Total checks performed: $total_checks"
    echo "Files/directories found: $found_files"
    echo ""
    
    if [ "$found_files" -eq 0 ]; then
        log_info "✓ All nemo-git-integration files successfully removed!"
        echo ""
        log_info "Nemo Git Integration has been completely uninstalled."
        return 0
    else
        log_error "✗ Found $found_files remaining file(s) or directory(ies)."
        echo ""
        log_error "Some nemo-git-integration files are still present."
        log_info "To remove remaining files, you may need to:"
        log_info "  1. Run: sudo $0 --system (if system files remain)"
        log_info "  2. Manually remove the files listed above"
        log_info "  3. Clear Nemo cache: rm -rf ~/.cache/nemo"
        log_info "  4. Restart Nemo: nemo -q && sleep 2 && nemo &"
        return 1
    fi
}

# Main verification process
run_verification() {
    echo "=========================================="
    echo "Nemo Git Integration - Removal Verification"
    echo "=========================================="
    echo ""
    
    verify_system_wide
    verify_user_local
    check_nemo_running
    display_verification_summary
}

# Main uninstall process
run_uninstall() {
    echo "=========================================="
    echo "Nemo Git Integration - Uninstall"
    echo "=========================================="
    echo ""
    
    case "$MODE" in
        user)
            remove_user_local
            restart_nemo
            ;;
        system)
            remove_system_wide
            # Try to restart Nemo for the user who invoked sudo
            if [ -n "${SUDO_USER:-}" ]; then
                # Validate SUDO_USER: only allow alphanumeric, underscore, hyphen
                if ! echo "$SUDO_USER" | grep -qE '^[a-zA-Z0-9_-]+$'; then
                    log_warn "Invalid SUDO_USER value, skipping Nemo restart"
                else
                    log_info "Attempting to restart Nemo for user: $SUDO_USER"
                    # Preserve the user's DISPLAY environment variable
                    SUDO_USER_DISPLAY=$(su - "$SUDO_USER" -c 'echo $DISPLAY' 2>/dev/null || echo ":0")
                    su - "$SUDO_USER" -c "nemo -q 2>/dev/null || true; sleep 2; DISPLAY=${SUDO_USER_DISPLAY} nohup nemo >/dev/null 2>&1 &" || true
                fi
            fi
            ;;
        all)
            remove_user_local
            remove_system_wide
            restart_nemo
            ;;
    esac
    
    echo ""
    echo "=========================================="
    echo "Uninstall Complete!"
    echo "=========================================="
    echo ""
    log_info "To verify complete removal, run: $0 --verify"
    echo ""
    log_info "If Git menu items still appear in Nemo:"
    log_info "  1. Completely quit Nemo: nemo -q"
    log_info "  2. Wait a few seconds"
    log_info "  3. Restart Nemo or log out and log back in"
    log_info "  4. Run: rm -rf ~/.cache/nemo"
    echo ""
}

# Main entry point
main() {
    if [ "$VERIFY_MODE" = true ]; then
        run_verification
    else
        # Enable exit on error for uninstall mode
        set -e
        run_uninstall
    fi
}

main "$@"
