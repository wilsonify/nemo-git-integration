#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  SOURCE_DIR="/mnt/SSD1/mrepos/github.com/wilsonify/nemo-git-integration/nemo-git-integration"
  SCRIPT="$TEST_DIR/s03b-add.sh"
  cp "$SOURCE_DIR/s03-update/s03b-add.sh" "$SCRIPT"
  chmod +x "$SCRIPT"

  # Setup mock zenity that logs calls
  export PATH="$TEST_DIR:$PATH"
  ZENITY_LOG="$TEST_DIR/zenity_log.txt"
  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity Mock] $@" >> "$ZENITY_LOG"
if [[ "$*" == *"--question"* ]]; then
  # Simulate user clicking "OK" on question dialog
  exit 0
elif [[ "$*" == *"--error"* ]]; then
  # Print error and exit 1
  echo "Error dialog: $*"
  exit 1
elif [[ "$*" == *"--warning"* ]]; then
  echo "Warning dialog: $*"
  exit 1
fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  # Initialize git repo with some files
  cd "$TEST_DIR"
  git config --global init.defaultBranch main
  git init
  echo "Hello" > file1.txt
  echo "World" > file2.txt
  git add .
  git commit -m "Initial commit"


  # Files should exist for adding
  touch "$TEST_DIR/file3.txt"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "adds selected files successfully and shows zenity info" {
  run "$SCRIPT" "$TEST_DIR" "file1.txt" "file3.txt"

  [ "$status" -eq 0 ]

  # Check that files were staged
  run git diff --name-only --cached
  [[ "${output}" == *file1.txt* ]]
  [[ "${output}" == *file3.txt* ]]

  # Check zenity question and info calls in log
  grep -q -- "--question" "$ZENITY_LOG"
  grep -q -- "--info" "$ZENITY_LOG"
}

@test "shows zenity error if target directory not accessible" {
  run "$SCRIPT" "/nonexistent/dir" "file1.txt"
  [ "$status" -ne 0 ]
  grep -q "Directory Error" "$ZENITY_LOG"
}

@test "shows zenity error if not a git repository" {
  mkdir -p "$TEST_DIR/notagit"
  run "$SCRIPT" "$TEST_DIR/notagit" "file1.txt"
  [ "$status" -ne 0 ]
  grep -q "Not a Git Repository" "$ZENITY_LOG"
}

@test "exits cleanly when user cancels add confirmation" {
  # Override zenity mock for question dialog to simulate cancel
  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity Mock] $@" >> "$ZENITY_LOG"
if [[ "$*" == *"--question"* ]]; then
  # Simulate user clicking "Cancel"
  exit 1
fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  run "$SCRIPT" "$TEST_DIR" "file1.txt"
  [ "$status" -eq 0 ]
  # No files should be staged
  run git diff --name-only --cached
  [[ "${output}" != *file1.txt* ]]
}
