#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  SOURCE_DIR="${BATS_TEST_DIRNAME}/../nemo-git-integration"
  SCRIPT="$TEST_DIR/s04a-reset.sh"
  cp "$SOURCE_DIR/s04-delete/s04a-reset.sh" "$SCRIPT"
  chmod +x "$SCRIPT"

  # Zenity mock
  ZENITY_LOG="$TEST_DIR/zenity_log.txt"
  export ZENITY_LOG
  export PATH="$TEST_DIR:$PATH"

  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity Mock] $@" >> "$ZENITY_LOG"
if [[ "$*" == *"--question"* ]]; then
  exit 0  # simulate confirmation
elif [[ "$*" == *"--error"* || "$*" == *"--warning"* ]]; then
  exit 1
fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  # Create Git repo
  cd "$TEST_DIR"
  git config --global init.defaultBranch main
  git init
  echo "original" > tracked.txt
  git add tracked.txt
  git commit -m "Initial commit"
  echo "edited" > tracked.txt  # Modify file for restoration
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "restores modified tracked files" {
  run "$SCRIPT" "$TEST_DIR" "tracked.txt"
  [ "$status" -eq 0 ]

  run cat tracked.txt
  [ "$output" = "original" ]

  run grep -- "--question" "$ZENITY_LOG"
  run grep -- "--info" "$ZENITY_LOG"
}

@test "shows zenity error if target directory is missing" {
  run "$SCRIPT" "/nonexistent/dir" "file.txt"
  [ "$status" -ne 0 ]
  run grep -- "Directory Error" "$ZENITY_LOG"
}

@test "shows error if directory is not a git repo" {
  mkdir "$TEST_DIR/notagit"
  run "$SCRIPT" "$TEST_DIR/notagit" "file.txt"
  [ "$status" -ne 0 ]
  run grep -- "Not a Git Repository" "$ZENITY_LOG"
}

@test "cancels reset when user declines confirmation" {
  # Simulate cancel
  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity Mock Cancel] $@" >> "$ZENITY_LOG"
if [[ "$*" == *"--question"* ]]; then
  exit 1  # simulate cancel
fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  echo "changed again" > tracked.txt
  run "$SCRIPT" "$TEST_DIR" "tracked.txt"
  [ "$status" -eq 0 ]  # Exit cleanly

  run cat tracked.txt
  [ "$output" = "changed again" ]

  run grep -- "Reset Cancelled" "$ZENITY_LOG"
}

