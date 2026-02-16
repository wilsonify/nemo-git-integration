#!/usr/bin/env bash
#
# verify-removal.sh - Verify complete removal of nemo-git-integration
#
# Usage:
#   ./verify-removal.sh
#
# This script checks for any remaining nemo-git-integration files in:
#   - System-wide locations (/usr/share, /etc/xdg)
#   - User-local locations (~/.local, ~/.config, ~/.cache)
#
# Exit codes:
#   0 - All files removed successfully
#   1 - Some files still remain
#

set -uo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

found_files=0
total_checks=0

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

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

# Check system-wide locations
check_system_wide() {
    log_info "Checking system-wide installation locations..."
    
    local action_files=(
        "git01a-init.nemo_action" "git01b-clone.nemo_action" "git01c-branch.nemo_action"
        "git02a-status.nemo_action" "git02c-log.nemo_action" "git02d-fetch.nemo_action"
        "git03a-pull.nemo_action" "git03b-add.nemo_action" "git03c-commit.nemo_action"
        "git03d-push.nemo_action" "git04a-reset.nemo_action" "git04b-uninit.nemo_action"
        "git04c-unclone.nemo_action" "git04e-unpull.nemo_action" "git04f-unadd.nemo_action"
        "git04g-uncommit.nemo_action" "git04h-unpush.nemo_action"
    )
    
    for action in "${action_files[@]}"; do
        check_file "/usr/share/nemo/actions/$action" "System action: $action"
    done
    
    check_directory "/usr/share/nemo-git-integration" "System scripts directory"
    check_file "/usr/share/nemo-python/extensions/nemo_git_status.py" "System Python extension"
    check_file "/etc/xdg/nemo/actions/actions-tree.json" "System config file"
    
    local icon_files=(
        "add-file.png" "construction.png" "create.png"
        "happy-file.png" "important-file.png" "winking-file.png"
    )
    
    for icon in "${icon_files[@]}"; do
        check_file "/usr/share/icons/hicolor/scalable/apps/$icon" "System icon: $icon"
    done
}

# Check user-local locations
check_user_local() {
    log_info "Checking user-local installation locations..."
    
    local HOME_DIR="${HOME}"
    local action_files=(
        "git01a-init.nemo_action" "git01b-clone.nemo_action" "git01c-branch.nemo_action"
        "git02a-status.nemo_action" "git02c-log.nemo_action" "git02d-fetch.nemo_action"
        "git03a-pull.nemo_action" "git03b-add.nemo_action" "git03c-commit.nemo_action"
        "git03d-push.nemo_action" "git04a-reset.nemo_action" "git04b-uninit.nemo_action"
        "git04c-unclone.nemo_action" "git04e-unpull.nemo_action" "git04f-unadd.nemo_action"
        "git04g-uncommit.nemo_action" "git04h-unpush.nemo_action"
    )
    
    for action in "${action_files[@]}"; do
        check_file "$HOME_DIR/.local/share/nemo/actions/$action" "User action: $action"
    done
    
    check_directory "$HOME_DIR/.local/share/nemo/nemo-git-integration" "User scripts directory"
    check_file "$HOME_DIR/.local/share/nemo-python/extensions/nemo_git_status.py" "User Python extension"
    check_file "$HOME_DIR/.config/nemo/actions/actions-tree.json" "User config file"
    
    local icon_files=(
        "add-file.png" "construction.png" "create.png"
        "happy-file.png" "important-file.png" "winking-file.png"
    )
    
    for icon in "${icon_files[@]}"; do
        check_file "$HOME_DIR/.local/share/icons/$icon" "User icon: $icon"
    done
}

# Check Nemo processes
check_nemo_running() {
    log_info "Checking for running Nemo processes..."
    
    if pgrep -x nemo >/dev/null; then
        log_warn "Nemo is still running. For complete cleanup, restart Nemo."
        log_warn "  Run: nemo -q && sleep 2 && nemo &"
    else
        log_info "No Nemo processes found."
    fi
}

# Display summary
display_summary() {
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
        log_info "  1. Run with sudo if system files remain: sudo ./verify-removal.sh"
        log_info "  2. Manually remove the files listed above"
        log_info "  3. Clear Nemo cache: rm -rf ~/.cache/nemo"
        log_info "  4. Restart Nemo: nemo -q && sleep 2 && nemo &"
        return 1
    fi
}

# Main verification process
main() {
    echo "=========================================="
    echo "Nemo Git Integration - Removal Verification"
    echo "=========================================="
    echo ""
    
    check_system_wide
    check_user_local
    check_nemo_running
    display_summary
}

main "$@"