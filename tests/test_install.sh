#!/usr/bin/env bats


@test "installation creates layout file" {
  run ./install.sh
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/nemo/actions/actions-tree.json" ]
}

@test "installation creates extension" {
  run ./install.sh
  [ "$status" -eq 0 ]
  [ -f "$HOME/.local/share/nemo-python/extensions/nemo_git_status.py" ]
}