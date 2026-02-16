# Uninstall and Cleanup Guide

This guide provides detailed instructions for completely removing nemo-git-integration from your system.

← [Back to User Guide](../user.md)

## Table of Contents

1. [Overview](#overview)
2. [Quick Uninstall](#quick-uninstall)
3. [Comprehensive Cleanup](#comprehensive-cleanup)
4. [Verification](#verification)
5. [Troubleshooting](#troubleshooting)
6. [Manual Cleanup](#manual-cleanup)
7. [Forcing Nemo to Reload](#forcing-nemo-to-reload)

## Overview

The nemo-git-integration package can be installed in two ways:

- **System-wide** (via `.deb` package): Files installed to `/usr/share/`, `/etc/xdg/`
- **User-local** (via `install.sh`): Files installed to `~/.local/`, `~/.config/`

Complete removal requires:

1. Removing installed files
2. Clearing Nemo caches
3. Forcing Nemo to reload configuration

## Quick Uninstall

### For User-Local Installation

```bash
./uninstall.sh
```

This will:

- Remove all `.nemo_action` files
- Remove script directories
- Remove Python extensions
- Remove configuration files
- Clear Nemo cache
- Restart Nemo

### For System-Wide Installation (Debian Package)

```bash
sudo apt-get purge nemo-git-integration
```

Or:

```bash
sudo dpkg --purge nemo-git-integration
```

The `purge` operation ensures complete removal including configuration files.

## Comprehensive Cleanup

If the standard uninstall leaves residual files, use the comprehensive cleanup script:

### Clean User-Local Installation Only

```bash
./cleanup-all.sh
```

### Clean System-Wide Installation Only

```bash
sudo ./cleanup-all.sh --system
```

### Clean Both User-Local and System-Wide

```bash
./cleanup-all.sh --all
```

Note: This requires `sudo` for system-wide cleanup.

## Verification

After uninstalling, verify complete removal:

```bash
./verify-removal.sh
```

This script checks:

- System-wide locations (`/usr/share/`, `/etc/xdg/`)
- User-local locations (`~/.local/`, `~/.config/`)
- Running Nemo processes

### Expected Output

If successful:

```
✓ All nemo-git-integration files successfully removed!
```

If files remain:

```
✗ Found N remaining file(s) or directory(ies).
```

## Troubleshooting

### Git Menu Items Still Appear After Uninstall

**Cause**: Nemo caches action files and doesn't automatically reload.

**Solutions** (try in order):

1. **Clear cache and restart Nemo:**

   ```bash
   rm -rf ~/.cache/nemo
   nemo -q
   sleep 2
   nemo &
   ```

2. **Log out and log back in:**
   This ensures all Nemo processes are terminated and caches are cleared.

3. **Reboot the system:**
   If the above doesn't work, a full reboot ensures complete cleanup.

### Permission Denied Errors

**Cause**: Trying to remove system files without root privileges.

**Solution**:

```bash
sudo ./cleanup-all.sh --system
```

### Nemo Won't Restart

**Cause**: Display environment not available or Nemo already running.

**Solution**:

```bash
# Kill all Nemo processes
killall nemo
# Wait a moment
sleep 2
# Restart Nemo
DISPLAY=:0 nemo &
```

### Files Still Present After Cleanup

**Cause**: Files installed in non-standard locations or by other tools.

**Solution**: See [Manual Cleanup](#manual-cleanup) section.

## Manual Cleanup

If automated scripts don't remove everything, manually check and remove files:

### System-Wide Locations

```bash
# Check and remove action files
sudo rm -f /usr/share/nemo/actions/git*.nemo_action

# Check and remove script directory
sudo rm -rf /usr/share/nemo-git-integration

# Check and remove Python extension
sudo rm -f /usr/share/nemo-python/extensions/nemo_git_status.py
sudo rm -rf /usr/share/nemo-python/extensions/__pycache__

# Check and remove configuration
sudo rm -f /etc/xdg/nemo/actions/actions-tree.json

# Check and remove icons
sudo rm -f /usr/share/icons/hicolor/scalable/apps/{add-file,construction,create,happy-file,important-file,winking-file}.png

# Update icon cache
sudo gtk-update-icon-cache -f /usr/share/icons/hicolor
```

### User-Local Locations

```bash
# Check and remove action files
rm -f ~/.local/share/nemo/actions/git*.nemo_action

# Check and remove script directory
rm -rf ~/.local/share/nemo/nemo-git-integration

# Check and remove Python extension
rm -f ~/.local/share/nemo-python/extensions/nemo_git_status.py
rm -rf ~/.local/share/nemo-python/extensions/__pycache__

# Check and remove configuration
rm -f ~/.config/nemo/actions/actions-tree.json

# Check and remove icons
rm -f ~/.local/share/icons/{add-file,construction,create,happy-file,important-file,winking-file}.png

# Clear Nemo cache
rm -rf ~/.cache/nemo
```

## Forcing Nemo to Reload

Nemo caches configuration and action files. To force a complete reload:

### Method 1: Restart Nemo (Quickest)

```bash
nemo -q          # Quit Nemo
sleep 2          # Wait for complete shutdown
nemo &           # Restart in background
```

### Method 2: Clear Cache and Restart

```bash
rm -rf ~/.cache/nemo    # Remove cache
nemo -q                 # Quit Nemo
sleep 2                 # Wait
nemo &                  # Restart
```

### Method 3: Log Out and Log Back In

This is the most thorough method:

1. Save all work
2. Log out of your session
3. Log back in
4. Nemo will start fresh with no cached data

### Method 4: Reboot (Most Thorough)

For complete certainty:

```bash
sudo reboot
```

### Method 5: Using Desktop Environment Tools

If using Cinnamon:

1. Open System Settings
2. Go to "Extensions" or "Nemo Settings"
3. Disable/Enable or restart Nemo from there

## Validation Checklist for Maintainers

Use this checklist to confirm complete removal:

- [ ] Run `./verify-removal.sh` - all checks pass
- [ ] Right-click a folder in Nemo - no Git menu items appear
- [ ] Check `~/.local/share/nemo/actions/` - no `git*.nemo_action` files
- [ ] Check `/usr/share/nemo/actions/` - no `git*.nemo_action` files
- [ ] Check `~/.cache/nemo/` - directory doesn't exist or is empty
- [ ] No `nemo_git_status.py` in `~/.local/share/nemo-python/extensions/`
- [ ] No `nemo_git_status.py` in `/usr/share/nemo-python/extensions/`
- [ ] Nemo restarts without errors
- [ ] No nemo-git-integration package in `dpkg -l | grep nemo-git`

## Advanced: Infrastructure-as-Code Testing

For automated testing in CI/CD:

```bash
#!/bin/bash
# Test complete uninstall

# Install the package
./install.sh

# Verify installation
test -f ~/.local/share/nemo/actions/git01a-init.nemo_action

# Uninstall
./uninstall.sh

# Verify removal
./verify-removal.sh
EXIT_CODE=$?

# Exit with verification result
exit $EXIT_CODE
```

## File Locations Reference

### System-Wide Installation Paths

| Type | Location |
|------|----------|
| Action files | `/usr/share/nemo/actions/*.nemo_action` |
| Shell scripts | `/usr/share/nemo-git-integration/s0*/*.sh` |
| Python extension | `/usr/share/nemo-python/extensions/nemo_git_status.py` |
| Configuration | `/etc/xdg/nemo/actions/actions-tree.json` |
| Icons | `/usr/share/icons/hicolor/scalable/apps/*.png` |

### User-Local Installation Paths

| Type | Location |
|------|----------|
| Action files | `~/.local/share/nemo/actions/*.nemo_action` |
| Shell scripts | `~/.local/share/nemo/nemo-git-integration/s0*/*.sh` |
| Python extension | `~/.local/share/nemo-python/extensions/nemo_git_status.py` |
| Configuration | `~/.config/nemo/actions/actions-tree.json` |
| Icons | `~/.local/share/icons/*.png` |
| Cache | `~/.cache/nemo/` |

## Getting Help

If you continue to experience issues after following this guide:

1. Check the [GitHub Issues](https://github.com/wilsonify/nemo-git-integration/issues)
2. Run `./verify-removal.sh` and include output in your issue report
3. Provide Nemo version: `nemo --version`
4. Provide OS information: `lsb_release -a`

## See Also

- [README.md](../README.md) - Installation and usage
- [debian/postrm](../debian/postrm) - Debian package removal script
- [uninstall.sh](../uninstall.sh) - User-local uninstall script
- [cleanup-all.sh](../cleanup-all.sh) - Comprehensive cleanup script
- [verify-removal.sh](../verify-removal.sh) - Verification script
