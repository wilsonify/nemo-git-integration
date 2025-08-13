#!/usr/bin/env bats

@test "uninstall removes layout file" {
  # Create dummy layout file to simulate installed state
  mkdir -p "$HOME/.config/nemo/actions"
  touch "$HOME/.config/nemo/actions/actions-tree.json"
  run ./uninstall.sh
  [ "$status" -eq 0 ]
  [ ! -f "$HOME/.config/nemo/actions/actions-tree.json" ]
}
