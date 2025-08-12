#!/usr/bin/env bats

setup() {
  export HOME="$(mktemp -d)"
  mkdir -p "$HOME/.local/share"
  mkdir -p "$BATS_TEST_TMPDIR/src/icons" "$BATS_TEST_TMPDIR/src/nemo/actions" "$BATS_TEST_TMPDIR/src/nemo-git-integration"

  echo "fakeicon" > "$BATS_TEST_TMPDIR/src/icons/icon1.png"
  echo "Path: __HOME__/myfile" > "$BATS_TEST_TMPDIR/src/nemo/actions/test.nemo_action"
  echo '{ "toplevel": [] }' > "$BATS_TEST_TMPDIR/src/nemo-git-integration/actions-tree.json"

  cp ./install.sh "$BATS_TEST_TMPDIR/install.sh"
  chmod +x "$BATS_TEST_TMPDIR/install.sh"

  cd "$BATS_TEST_TMPDIR/src"
}

teardown() {
  rm -rf "$HOME" "$BATS_TEST_TMPDIR"
}

@test "backup creation" {
  run ../install.sh
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/nemo/actions/actions-tree-bkup.json" ]
}

@test "files copied" {
  run ../install.sh
  [ "$status" -eq 0 ]
  [ -f "$HOME/.local/share/icons/icon1.png" ]
  [ -f "$HOME/.local/share/nemo/actions/test.nemo_action" ]
  [ -f "$HOME/.config/nemo/actions/actions-tree.json" ]
}

@test "placeholder replacement" {
  run ../install.sh
  [ "$status" -eq 0 ]
  grep -q "$HOME/myfile" "$HOME/.local/share/nemo/actions/test.nemo_action"
}

@test "fails if integration JSON missing" {
  rm nemo-git-integration/actions-tree.json
  run ../install.sh
  [ "$status" -ne 0 ]
  [[ "$output" == *ERROR* ]]
}
