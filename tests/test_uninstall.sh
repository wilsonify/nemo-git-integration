#!/usr/bin/env bats

setup() {
  export HOME="$(mktemp -d)"
  mkdir -p "$HOME/.config/nemo/actions"
  cp ./uninstall.sh "$BATS_TEST_TMPDIR/uninstall.sh"
  chmod +x "$BATS_TEST_TMPDIR/uninstall.sh"
  cd "$BATS_TEST_TMPDIR"
}

teardown() {
  rm -rf "$HOME" "$BATS_TEST_TMPDIR"
}

@test "uninstall removes layout file" {
  # Create dummy layout file to simulate installed state
  mkdir -p "$HOME/.config/nemo/actions"
  touch "$HOME/.config/nemo/actions/actions-tree.json"

  run ./uninstall.sh
  [ "$status" -eq 0 ]

  [ ! -f "$HOME/.config/nemo/actions/actions-tree.json" ]
}
