#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  SOURCE_DIR="${BATS_TEST_DIRNAME}/../nemo-git-integration"
  SCRIPT="$TEST_DIR/s04b-uninit.sh"
  cp "$SOURCE_DIR/s04-delete/s04b-uninit.sh" "$SCRIPT"
  chmod +x "$SCRIPT"

  # Mock zenity with log
  ZENITY_LOG="$TEST_DIR/zenity_log.txt"
  export ZENITY_LOG
  export PATH="$TEST_DIR:$PATH"

  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity Mock] $@" >> "$ZENITY_LOG"
if [[ "$*" == *"--question"* ]]; then
  exit 0  # simulate user says "Yes"
elif [[ "$*" == *"--error"* || "$*" == *"--warning"* ]]; then
  exit 1
fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  # Setup minimal Git repo
  cd "$TEST_DIR"
  git config --global init.defaultBranch main
  git init > /dev/null
}

teardown() {
  /bin/rm -rf "$TEST_DIR"
}

@test "successfully uninitializes a Git repo" {
  [ -d "$TEST_DIR/.git" ]

  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ ! -d "$TEST_DIR/.git" ]

  run grep -- "--question" "$ZENITY_LOG"
  run grep -- "--info" "$ZENITY_LOG"
}

@test "fails if directory is not accessible" {
  run "$SCRIPT" "/nonexistent/dir"
  [ "$status" -ne 0 ]
  run grep -- "Directory Error" "$ZENITY_LOG"
}

@test "warns if directory is not a git repository" {
  mkdir "$TEST_DIR/notagit"
  run "$SCRIPT" "$TEST_DIR/notagit"
  [ "$status" -ne 0 ]
  run grep -- "No Git Repo" "$ZENITY_LOG"
}

@test "aborts cleanly when user cancels uninit" {
  # simulate cancel
  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity Mock Cancel] $@" >> "$ZENITY_LOG"
if [[ "$*" == *"--question"* ]]; then
  exit 1
fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ -d "$TEST_DIR/.git" ]

  run grep -- "Uninit Cancelled" "$ZENITY_LOG"
}

@test "shows error if .git removal fails" {
  # Mock rm to simulate failure (works even as root, unlike chmod)
  cat <<'EOF' > "$TEST_DIR/rm"
#!/bin/bash
echo "[rm Mock] $@" >> "$ZENITY_LOG"
exit 1  # Simulate rm failure
EOF
  chmod +x "$TEST_DIR/rm"

  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -ne 0 ]

  run grep -- "Git Uninit Failed" "$ZENITY_LOG"
}
