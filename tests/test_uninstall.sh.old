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
  rm -rf "$HOME/.cache/nemo" 2>/dev/null || true
}

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