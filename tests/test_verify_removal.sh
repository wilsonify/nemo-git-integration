#!/usr/bin/env bats

setup() {
  # Create clean test environment
  export TEST_HOME="$BATS_TMPDIR/test-home-$$"
  mkdir -p "$TEST_HOME"
  
  # Override HOME for testing
  export REAL_HOME="$HOME"
  export HOME="$TEST_HOME"
}

teardown() {
  # Restore HOME and clean up
  export HOME="$REAL_HOME"
  rm -rf "$TEST_HOME" 2>/dev/null || true
}

@test "verify-removal detects no files when clean" {
  # Run verification on clean system
  run ./verify-removal.sh
  [ "$status" -eq 0 ]
  [[ "$output" =~ "All nemo-git-integration files successfully removed" ]]
}

@test "verify-removal detects user action files" {
  # Create a user action file
  mkdir -p "$HOME/.local/share/nemo/actions"
  touch "$HOME/.local/share/nemo/actions/git01a-init.nemo_action"
  
  run ./verify-removal.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "User action: git01a-init.nemo_action" ]]
}

@test "verify-removal detects user script directory" {
  # Create user script directory
  mkdir -p "$HOME/.local/share/nemo/nemo-git-integration"
  
  run ./verify-removal.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "User scripts directory" ]]
}

@test "verify-removal detects Python extension" {
  # Create Python extension
  mkdir -p "$HOME/.local/share/nemo-python/extensions"
  touch "$HOME/.local/share/nemo-python/extensions/nemo_git_status.py"
  
  run ./verify-removal.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "User Python extension" ]]
}

@test "verify-removal detects config file" {
  # Create config file
  mkdir -p "$HOME/.config/nemo/actions"
  touch "$HOME/.config/nemo/actions/actions-tree.json"
  
  run ./verify-removal.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "User config file" ]]
}

@test "verify-removal detects icon files" {
  # Create icon file
  mkdir -p "$HOME/.local/share/icons"
  touch "$HOME/.local/share/icons/add-file.png"
  
  run ./verify-removal.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "User icon: add-file.png" ]]
}

@test "verify-removal counts multiple files correctly" {
  # Create multiple files
  mkdir -p "$HOME/.local/share/nemo/actions"
  mkdir -p "$HOME/.local/share/icons"
  touch "$HOME/.local/share/nemo/actions/git01a-init.nemo_action"
  touch "$HOME/.local/share/nemo/actions/git02a-status.nemo_action"
  touch "$HOME/.local/share/icons/add-file.png"
  
  run ./verify-removal.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Files/directories found: 3" ]]
}