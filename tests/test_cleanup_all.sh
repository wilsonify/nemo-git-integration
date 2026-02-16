#!/usr/bin/env bats

setup() {
  # Create clean test environment
  export TEST_HOME="$BATS_TMPDIR/test-cleanup-$$"
  mkdir -p "$TEST_HOME"
  
  # Override HOME for testing
  export REAL_HOME="$HOME"
  export HOME="$TEST_HOME"
  
  # Create test directories and files
  mkdir -p "$HOME/.config/nemo/actions"
  mkdir -p "$HOME/.local/share/nemo/actions"
  mkdir -p "$HOME/.local/share/nemo/nemo-git-integration/s01-create"
  mkdir -p "$HOME/.local/share/nemo-python/extensions"
  mkdir -p "$HOME/.local/share/icons"
  mkdir -p "$HOME/.cache/nemo"
}

teardown() {
  # Restore HOME and clean up
  export HOME="$REAL_HOME"
  rm -rf "$TEST_HOME" 2>/dev/null || true
}

@test "cleanup-all removes user action files" {
  # Create dummy action files
  touch "$HOME/.local/share/nemo/actions/git01a-init.nemo_action"
  touch "$HOME/.local/share/nemo/actions/git02a-status.nemo_action"
  
  run ./cleanup-all.sh
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.local/share/nemo/actions/git01a-init.nemo_action" ]
  [ ! -f "$HOME/.local/share/nemo/actions/git02a-status.nemo_action" ]
}

@test "cleanup-all removes script directory" {
  # Create dummy script directory
  touch "$HOME/.local/share/nemo/nemo-git-integration/s01-create/test.sh"
  
  run ./cleanup-all.sh
  [ "$status" -eq 0 ]
  [ ! -d "$HOME/.local/share/nemo/nemo-git-integration" ]
}

@test "cleanup-all removes Python extension" {
  # Create dummy extension
  touch "$HOME/.local/share/nemo-python/extensions/nemo_git_status.py"
  mkdir -p "$HOME/.local/share/nemo-python/extensions/__pycache__"
  
  run ./cleanup-all.sh
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.local/share/nemo-python/extensions/nemo_git_status.py" ]
  [ ! -d "$HOME/.local/share/nemo-python/extensions/__pycache__" ]
}

@test "cleanup-all removes config file" {
  # Create dummy config
  touch "$HOME/.config/nemo/actions/actions-tree.json"
  
  run ./cleanup-all.sh
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.config/nemo/actions/actions-tree.json" ]
}

@test "cleanup-all removes icon files" {
  # Create dummy icons
  touch "$HOME/.local/share/icons/add-file.png"
  touch "$HOME/.local/share/icons/construction.png"
  
  run ./cleanup-all.sh
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.local/share/icons/add-file.png" ]
  [ ! -f "$HOME/.local/share/icons/construction.png" ]
}

@test "cleanup-all clears Nemo cache" {
  # Create dummy cache
  touch "$HOME/.cache/nemo/test-cache"
  
  run ./cleanup-all.sh
  [ "$status" -eq 0 ]
  [ ! -d "$HOME/.cache/nemo" ]
}

@test "cleanup-all is idempotent" {
  # First cleanup
  run ./cleanup-all.sh
  [ "$status" -eq 0 ]
  
  # Second cleanup should also succeed
  run ./cleanup-all.sh
  [ "$status" -eq 0 ]
}

@test "cleanup-all handles missing files gracefully" {
  # Don't create any files, just run cleanup
  run ./cleanup-all.sh
  [ "$status" -eq 0 ]
}

@test "cleanup-all with --help shows usage" {
  run ./cleanup-all.sh --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
}