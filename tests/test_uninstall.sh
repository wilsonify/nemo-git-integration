#!/usr/bin/env bats

setup() {
  # Create test directories
  mkdir -p "$HOME/.config/nemo/actions"
  mkdir -p "$HOME/.local/share/nemo/actions"
  mkdir -p "$HOME/.local/share/nemo/nemo-git-integration/s01-create"
  mkdir -p "$HOME/.local/share/nemo-python/extensions"
  mkdir -p "$HOME/.local/share/icons"
  mkdir -p "$HOME/.cache/nemo"
}

teardown() {
  # Clean up test artifacts
  rm -rf "$HOME/.config/nemo" 2>/dev/null || true
  rm -rf "$HOME/.local/share/nemo" 2>/dev/null || true
  rm -rf "$HOME/.local/share/nemo-python" 2>/dev/null || true
  rm -rf "$HOME/.local/share/icons" 2>/dev/null || true
  rm -rf "$HOME/.cache/nemo" 2>/dev/null || true
}

# ========================================
# Tests for default user-local uninstall
# ========================================

@test "uninstall removes layout file" {
  # Create dummy layout file to simulate installed state
  touch "$HOME/.config/nemo/actions/actions-tree.json"
  
  run ./uninstall.sh
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.config/nemo/actions/actions-tree.json" ]
}

@test "uninstall removes extension file" {
  # Create dummy extension file to simulate installed state
  touch "$HOME/.local/share/nemo-python/extensions/nemo_git_status.py"
  mkdir -p "$HOME/.local/share/nemo-python/extensions/__pycache__"
  # Create bytecode file without hardcoding Python version
  touch "$HOME/.local/share/nemo-python/extensions/__pycache__/nemo_git_status.pyc"
  
  run ./uninstall.sh
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.local/share/nemo-python/extensions/nemo_git_status.py" ]
  [ ! -d "$HOME/.local/share/nemo-python/extensions/__pycache__" ]
}

@test "uninstall removes action files" {
  # Create dummy action files
  touch "$HOME/.local/share/nemo/actions/git01a-init.nemo_action"
  touch "$HOME/.local/share/nemo/actions/git02a-status.nemo_action"
  
  run ./uninstall.sh
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.local/share/nemo/actions/git01a-init.nemo_action" ]
  [ ! -f "$HOME/.local/share/nemo/actions/git02a-status.nemo_action" ]
}

@test "uninstall removes script directory" {
  # Create dummy script directory
  touch "$HOME/.local/share/nemo/nemo-git-integration/s01-create/test.sh"
  
  run ./uninstall.sh
  [ "$status" -eq 0 ]
  [ ! -d "$HOME/.local/share/nemo/nemo-git-integration" ]
}

@test "uninstall removes icon files" {
  # Create dummy icon files
  touch "$HOME/.local/share/icons/add-file.png"
  touch "$HOME/.local/share/icons/construction.png"
  
  run ./uninstall.sh
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.local/share/icons/add-file.png" ]
  [ ! -f "$HOME/.local/share/icons/construction.png" ]
}

@test "uninstall clears Nemo cache" {
  # Create dummy cache
  touch "$HOME/.cache/nemo/test-cache"
  
  run ./uninstall.sh
  [ "$status" -eq 0 ]
  [ ! -d "$HOME/.cache/nemo" ]
}

@test "uninstall is idempotent" {
  # First uninstall
  run ./uninstall.sh
  [ "$status" -eq 0 ]
  
  # Second uninstall should also succeed
  run ./uninstall.sh
  [ "$status" -eq 0 ]
}

@test "uninstall handles missing files gracefully" {
  # Don't create any files, just run uninstall
  run ./uninstall.sh
  [ "$status" -eq 0 ]
}

# ========================================
# Tests for --help flag
# ========================================

@test "uninstall --help shows usage" {
  run ./uninstall.sh --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "--system" ]]
  [[ "$output" =~ "--verify" ]]
}

@test "uninstall -h shows usage" {
  run ./uninstall.sh -h
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}

# ========================================
# Tests for --verify flag
# ========================================

@test "uninstall --verify detects no files when clean" {
  # Create a temporary clean HOME for this test
  local CLEAN_HOME="/tmp/clean-home-$$"
  mkdir -p "$CLEAN_HOME"
  
  # Run verification on clean system with clean HOME
  HOME="$CLEAN_HOME" run ./uninstall.sh --verify
  [ "$status" -eq 0 ]
  [[ "$output" =~ "All nemo-git-integration files successfully removed" ]]
  
  # Cleanup
  rm -rf "$CLEAN_HOME"
}

@test "uninstall --verify detects user action files" {
  # Create a user action file
  touch "$HOME/.local/share/nemo/actions/git01a-init.nemo_action"
  
  run ./uninstall.sh --verify
  [ "$status" -eq 1 ]
  [[ "$output" =~ "User action: git01a-init.nemo_action" ]]
}

@test "uninstall --verify detects user script directory" {
  # Create user script directory
  mkdir -p "$HOME/.local/share/nemo/nemo-git-integration"
  
  run ./uninstall.sh --verify
  [ "$status" -eq 1 ]
  [[ "$output" =~ "User scripts directory" ]]
}

@test "uninstall --verify detects Python extension" {
  # Create Python extension
  touch "$HOME/.local/share/nemo-python/extensions/nemo_git_status.py"
  
  run ./uninstall.sh --verify
  [ "$status" -eq 1 ]
  [[ "$output" =~ "User Python extension" ]]
}

@test "uninstall --verify detects config file" {
  # Create config file
  touch "$HOME/.config/nemo/actions/actions-tree.json"
  
  run ./uninstall.sh --verify
  [ "$status" -eq 1 ]
  [[ "$output" =~ "User config file" ]]
}

@test "uninstall --verify detects icon files" {
  # Create icon file
  touch "$HOME/.local/share/icons/add-file.png"
  
  run ./uninstall.sh --verify
  [ "$status" -eq 1 ]
  [[ "$output" =~ "User icon: add-file.png" ]]
}

@test "uninstall --verify counts multiple files correctly" {
  # Use isolated HOME to avoid interference from setup()
  local TEST_HOME="/tmp/count-test-$$"
  mkdir -p "$TEST_HOME/.local/share/nemo/actions"
  mkdir -p "$TEST_HOME/.local/share/icons"
  touch "$TEST_HOME/.local/share/nemo/actions/git01a-init.nemo_action"
  touch "$TEST_HOME/.local/share/nemo/actions/git02a-status.nemo_action"
  touch "$TEST_HOME/.local/share/icons/add-file.png"
  
  HOME="$TEST_HOME" run ./uninstall.sh --verify
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Files/directories found: 3" ]]
  
  # Cleanup
  rm -rf "$TEST_HOME"
}

# ========================================
# Tests for integration: uninstall then verify
# ========================================

@test "uninstall then verify shows clean system" {
  # Create test files
  touch "$HOME/.local/share/nemo/actions/git01a-init.nemo_action"
  touch "$HOME/.local/share/icons/add-file.png"
  touch "$HOME/.config/nemo/actions/actions-tree.json"
  
  # Uninstall
  run ./uninstall.sh
  [ "$status" -eq 0 ]
  
  # Verify
  run ./uninstall.sh --verify
  [ "$status" -eq 0 ]
  [[ "$output" =~ "All nemo-git-integration files successfully removed" ]]
}

# ========================================
# Tests for error handling
# ========================================

@test "uninstall rejects unknown options" {
  run ./uninstall.sh --unknown-option
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unknown option" ]]
}
