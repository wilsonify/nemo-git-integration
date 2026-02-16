# Maintainer Validation Checklist - Uninstall Cleanup Fix

This document provides step-by-step validation procedures for maintainers to confirm the uninstall cleanup improvements work correctly.

← [Back to Developer Guide](../developer.md)

## Summary of Changes

### Files Modified

1. **`debian/postrm`** - Complete rewrite with proper cleanup logic
2. **`uninstall.sh`** - Improved to be selective and comprehensive
3. **`tests/test_uninstall.sh`** - Enhanced test coverage

### Files Added

1. **`verify-removal.sh`** - Verification script to check complete removal
2. **`cleanup-all.sh`** - Comprehensive cleanup for both user and system installations
3. **`docs/UNINSTALL.md`** - Complete uninstallation guide
4. **`tests/test_verify_removal.sh`** - Tests for verification script
5. **`tests/test_cleanup_all.sh`** - Tests for cleanup script

## Quick Validation

Run all tests to ensure everything works:

```bash
# Install BATS if not already installed
sudo apt-get install -y bats

# Run all uninstall-related tests
bats tests/test_uninstall.sh tests/test_verify_removal.sh tests/test_cleanup_all.sh
```

Expected result: All 23 tests should pass.

## Detailed Validation Procedures

### Test 1: User-Local Installation and Removal

**Purpose**: Verify user-local install/uninstall cycle works correctly.

**Steps**:

```bash
# 1. Install to user home directory
./install.sh

# 2. Verify files are installed
ls ~/.local/share/nemo/actions/git*.nemo_action
ls ~/.local/share/nemo/nemo-git-integration/
ls ~/.local/share/nemo-python/extensions/nemo_git_status.py
ls ~/.config/nemo/actions/actions-tree.json

# 3. Uninstall
./uninstall.sh

# 4. Verify complete removal
./verify-removal.sh
```

**Expected Result**:

- Step 2: All files should exist
- Step 4: Output should show "All nemo-git-integration files successfully removed!"

### Test 2: Debian Package Installation and Removal

**Purpose**: Verify system-wide package install/uninstall works correctly.

**Prerequisites**: Must have built the `.deb` package first.

**Steps**:

```bash
# 1. Build the package
make deb

# 2. Install the package
sudo dpkg -i ../nemo-git-integration_*.deb

# 3. Verify system-wide installation
ls /usr/share/nemo/actions/git*.nemo_action
ls /usr/share/nemo-git-integration/
ls /usr/share/nemo-python/extensions/nemo_git_status.py
ls /etc/xdg/nemo/actions/actions-tree.json

# 4. Purge the package
sudo dpkg --purge nemo-git-integration

# 5. Verify complete removal
sudo ./verify-removal.sh
```

**Expected Result**:

- Step 3: All system files should exist
- Step 5: Output should show "All nemo-git-integration files successfully removed!"

### Test 3: Cleanup Script Functionality

**Purpose**: Verify comprehensive cleanup script handles both installations.

**Steps**:

```bash
# 1. Install user-local
./install.sh

# 2. Run cleanup
./cleanup-all.sh

# 3. Verify removal
./verify-removal.sh
```

**Expected Result**:

- Step 3: Should report complete removal

### Test 4: Idempotency

**Purpose**: Verify scripts can be run multiple times safely.

**Steps**:

```bash
# Run uninstall multiple times
./uninstall.sh
./uninstall.sh
./uninstall.sh

# Run cleanup multiple times
./cleanup-all.sh
./cleanup-all.sh
./cleanup-all.sh

# Verify no errors and clean state
./verify-removal.sh
```

**Expected Result**:

- No errors from any script
- Final verification shows clean state

### Test 5: Nemo Context Menu Check

**Purpose**: Verify Git menu items disappear after uninstall (manual test).

**Prerequisites**:

- Nemo file manager installed
- Desktop environment running

**Steps**:

```bash
# 1. Install
./install.sh

# 2. Open Nemo and right-click a folder
# Verify: Git submenu appears with actions

# 3. Uninstall
./uninstall.sh

# 4. Clear Nemo cache and restart
rm -rf ~/.cache/nemo
nemo -q
sleep 2
nemo &

# 5. Open Nemo and right-click a folder again
# Verify: Git submenu no longer appears
```

**Expected Result**:

- After step 2: Git menu items visible
- After step 5: Git menu items NOT visible

### Test 6: Selective File Removal

**Purpose**: Verify uninstall doesn't delete unrelated user files.

**Steps**:

```bash
# 1. Create unrelated files in same directories
mkdir -p ~/.local/share/icons
touch ~/.local/share/icons/my-custom-icon.png
touch ~/.local/share/nemo/actions/my-custom-action.nemo_action

# 2. Install nemo-git-integration
./install.sh

# 3. Uninstall nemo-git-integration
./uninstall.sh

# 4. Verify custom files still exist
ls ~/.local/share/icons/my-custom-icon.png
ls ~/.local/share/nemo/actions/my-custom-action.nemo_action

# 5. Cleanup test files
rm ~/.local/share/icons/my-custom-icon.png
rm ~/.local/share/nemo/actions/my-custom-action.nemo_action
```

**Expected Result**:

- Step 4: Custom files should still exist (not deleted)

### Test 7: System-Wide Cleanup (Requires Root)

**Purpose**: Verify cleanup-all.sh can clean system-wide installation.

**Steps**:

```bash
# 1. Install system-wide via package
sudo dpkg -i ../nemo-git-integration_*.deb

# 2. Use cleanup script with --system flag
sudo ./cleanup-all.sh --system

# 3. Verify removal
sudo ./verify-removal.sh
```

**Expected Result**:

- Step 3: Should report complete removal

## Regression Testing

After changes, verify these scenarios don't break:

### Scenario 1: Normal Install/Uninstall Still Works

```bash
./install.sh && ./uninstall.sh
echo $?  # Should be 0
```

### Scenario 2: Package Building Still Works

```bash
make deb
echo $?  # Should be 0
ls -l ../nemo-git-integration_*.deb  # Package should exist
```

### Scenario 3: Existing Tests Still Pass

```bash
bats tests/test_*.sh
# All tests should pass
```

## Performance Testing

Verify scripts execute in reasonable time:

```bash
# Each should complete in under 5 seconds
time ./install.sh
time ./uninstall.sh
time ./cleanup-all.sh
time ./verify-removal.sh
```

## Edge Cases to Test

### Edge Case 1: Partial Installation

```bash
# Create only some files
mkdir -p ~/.local/share/nemo/actions
touch ~/.local/share/nemo/actions/git01a-init.nemo_action

# Run uninstall
./uninstall.sh

# Should handle gracefully without errors
echo $?  # Should be 0
```

### Edge Case 2: No Installation

```bash
# Run uninstall without any installation
./uninstall.sh

# Should handle gracefully
echo $?  # Should be 0
```

### Edge Case 3: Mixed Installation

```bash
# Install user-local
./install.sh

# Also manually copy a file to system location
sudo mkdir -p /usr/share/nemo/actions
sudo touch /usr/share/nemo/actions/git01a-init.nemo_action

# Run user cleanup
./cleanup-all.sh

# Verify user files removed but system file remains
./verify-removal.sh  # Should detect system file

# Cleanup system file
sudo ./cleanup-all.sh --system
```

## Documentation Validation

Verify documentation is accurate and helpful:

1. Read through `docs/UNINSTALL.md`
2. Follow each procedure listed
3. Confirm all commands work as documented
4. Check that troubleshooting steps resolve common issues

## Sign-Off Checklist

Mark each item as complete:

- [ ] All 23 automated tests pass
- [ ] User-local install/uninstall cycle works
- [ ] System-wide install/purge works
- [ ] Cleanup script removes all files
- [ ] Scripts are idempotent
- [ ] Nemo menu items disappear after uninstall
- [ ] Unrelated user files are preserved
- [ ] No errors in any normal usage scenario
- [ ] Documentation is accurate and complete
- [ ] Performance is acceptable (<5s per operation)
- [ ] Edge cases handled gracefully
- [ ] Regression tests pass

## Known Limitations

Document any known issues or limitations:

1. **Nemo Auto-restart**: The scripts attempt to restart Nemo, but this may not work in all desktop environments. Users may need to manually restart or log out/in.

2. **System-Wide Cache Clearing**: The `debian/postrm` script attempts to clear Nemo cache for logged-in users, but this is best-effort and may not work for all users.

3. **Icon Cache**: Icon cache updates require `gtk-update-icon-cache`, which may not be available on all systems.

## Troubleshooting for Maintainers

If validation fails:

1. **Check test output**: `bats -t tests/test_uninstall.sh` for detailed output
2. **Verify dependencies**: Ensure `jq`, `zenity`, `git` are installed
3. **Check permissions**: Some operations require write access to test directories
4. **Review logs**: Scripts output `[INFO]` and `[ERROR]` messages
5. **Manual inspection**: Use `ls -la` to check directories mentioned in verify-removal.sh

## Reporting Issues

If you find issues during validation:

1. Note which test/scenario failed
2. Capture full output/error messages
3. Document your environment (OS, Nemo version, installation method)
4. Create a GitHub issue with this information

## Additional Resources

- [UNINSTALL.md](UNINSTALL.md) - User-facing uninstall guide
- [debian/postrm](../debian/postrm) - Package removal script
- [uninstall.sh](../uninstall.sh) - User uninstall script
- [cleanup-all.sh](../cleanup-all.sh) - Comprehensive cleanup script
- [verify-removal.sh](../verify-removal.sh) - Verification script
