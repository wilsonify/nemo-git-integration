#!/usr/bin/env bats

@test "uninstall removes layout file" {
  # Create dummy layout file to simulate installed state
  mkdir -p "$HOME/.config/nemo/actions"
  touch "$HOME/.config/nemo/actions/actions-tree.json"
  run ./uninstall.sh
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.config/nemo/actions/actions-tree.json" ]
}

@test "uninstall removes extension file" {
  # Create dummy layout file to simulate installed state
  mkdir -p "$HOME/.local/share/nemo-python/extensions"
  touch "$HOME/.local/share/nemo-python/extensions/nemo_git_status.py"
  run ./uninstall.sh
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.local/share/nemo-python/extensions/nemo_git_status.py" ]
  [ ! -f "$HOME/.local/share/nemo-python/extensions/__pycache__" ]
}