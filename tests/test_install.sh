#!/usr/bin/env bats


@test "installation creates layout file" {
  run ./install.sh
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/nemo/actions/actions-tree.json" ]
}
