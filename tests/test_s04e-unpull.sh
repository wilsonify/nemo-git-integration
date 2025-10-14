#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  SCRIPT="$TEST_DIR/s04e-unpull.sh"
  SOURCE_DIR="${BATS_TEST_DIRNAME}/../nemo-git-integration"
  cp "$SOURCE_DIR/s04-delete/s04e-unpull.sh" "$SCRIPT"
  chmod +x "$SCRIPT"

  cd "$TEST_DIR"
  git init > /dev/null
  echo "init content" > file.txt
  git add file.txt
  git commit -m "init" > /dev/null

  export HOME="$TEST_DIR"
  mkdir -p "$HOME/.cache"

  # Zenity mock logs messages to file
  export ZENITY_LOG="$TEST_DIR/zenity_log.txt"
  export PATH="$TEST_DIR:$PATH"
  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity] $@" >> "$ZENITY_LOG"
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "fails if target dir is inaccessible" {
  NON_EXISTENT="$TEST_DIR/nonexistent"
  run "$SCRIPT" "$NON_EXISTENT"
  [ "$status" -eq 1 ]
  grep -q "Directory Error" "$ZENITY_LOG"
}

@test "fails if target is not a git repo" {
  mkdir -p "$TEST_DIR/not_a_git"
  run "$SCRIPT" "$TEST_DIR/not_a_git"
  [ "$status" -eq 1 ]
  grep -q "Not a Git Repository" "$ZENITY_LOG"
}

@test "fails if state directory missing" {
  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  grep -q "State Missing" "$ZENITY_LOG"
}

@test "fails if pull HEAD state file missing" {
  mkdir -p "$HOME/.cache/nemo_git_pull_state"
  echo "true" > "$HOME/.cache/nemo_git_pull_state/was_stashed"
  # no head_before_pull file
  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  grep -q "Missing saved HEAD commit hash" "$ZENITY_LOG"
}

@test "exits cleanly if no pull to undo (HEAD matches)" {
  mkdir -p "$HOME/.cache/nemo_git_pull_state"
  git rev-parse HEAD > "$HOME/.cache/nemo_git_pull_state/head_before_pull"
  echo "false" > "$HOME/.cache/nemo_git_pull_state/was_stashed"

  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  grep -q "Nothing to Undo" "$ZENITY_LOG"
}

@test "successful reset without stash" {
  mkdir -p "$HOME/.cache/nemo_git_pull_state"
  ORIGINAL_HEAD=$(git rev-parse HEAD)
  echo "$ORIGINAL_HEAD" > "$HOME/.cache/nemo_git_pull_state/head_before_pull"
  echo "false" > "$HOME/.cache/nemo_git_pull_state/was_stashed"

  # Make a new commit to simulate pull changed HEAD
  echo "change" > file.txt
  git add file.txt
  git commit -m "change" > /dev/null

  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  # Check that HEAD reset to original
  run git rev-parse HEAD
  [ "$output" = "$ORIGINAL_HEAD" ]
  grep -q "Unpull Success" "$ZENITY_LOG"
}
