#!/usr/bin/env bats



setup() {
  # Create a fake HOME for isolation
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  mkdir -p "$HOME/.local/share"

  # Create a fake source structure
  mkdir -p "$BATS_TEST_TMPDIR/src/icons"
  mkdir -p "$BATS_TEST_TMPDIR/src/nemo/actions"
  mkdir -p "$BATS_TEST_TMPDIR/src/nemo-git-integration"

  echo "fakeicon" > "$BATS_TEST_TMPDIR/src/icons/icon1.png"
  echo "FAKEACTION" > "$BATS_TEST_TMPDIR/src/nemo/actions/test.nemo_action"
  echo '{ "tree": "fake" }' > "$BATS_TEST_TMPDIR/src/nemo-git-integration/actions-tree.json"

  # Copy install.sh into tmpdir so paths are relative
  cp ./install.sh "$BATS_TEST_TMPDIR/install.sh"
  chmod +x "$BATS_TEST_TMPDIR/install.sh"

  cd "$BATS_TEST_TMPDIR/src"
}

teardown() {
  rm -rf "$TEST_HOME" "$BATS_TEST_TMPDIR"
}

@test "install.sh creates backup of actions-tree.json" {
  run ../install.sh
  [ "$status" -eq 0 ]
  [ -f "$HOME/.local/share/nemo-git-integration/actions-tree-bkup.json" ]
}

@test "install.sh copies icons, nemo, and nemo-git-integration" {
  run ../install.sh
  [ "$status" -eq 0 ]
  [ -f "$HOME/.local/share/icons/icon1.png" ]
  [ -f "$HOME/.local/share/nemo/actions/test.nemo_action" ]
  [ -f "$HOME/.local/share/nemo-git-integration/actions-tree.json" ]
}

@test "install.sh replaces __HOME__ placeholders" {
  # Add a placeholder in test file
  echo "Path: __HOME__/myfile" > nemo/actions/test.nemo_action
  run ../install.sh
  [ "$status" -eq 0 ]
  grep "$HOME/myfile" "$HOME/.local/share/nemo/actions/test.nemo_action"
}

@test "install.sh fails gracefully if actions-tree.json missing" {
  rm nemo-git-integration/actions-tree.json
  run ../install.sh
  [ "$status" -ne 0 ]
  [[ "$output" =~ "ERROR" ]]
}
