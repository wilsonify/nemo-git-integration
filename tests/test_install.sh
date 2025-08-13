#!/usr/bin/env bats

setup() {
  export HOME="$(mktemp -d)"
  mkdir -p "$HOME/.config/nemo/actions"
  cp ./install.sh "$BATS_TEST_TMPDIR/install.sh"
  chmod +x "$BATS_TEST_TMPDIR/install.sh"
  cd "$BATS_TEST_TMPDIR"
}

teardown() {
  rm -rf "$HOME" "$BATS_TEST_TMPDIR"
}

@test "installation creates layout file" {
  run ./install.sh
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/nemo/actions/actions-tree.json" ]
}
