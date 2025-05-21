#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  SOURCE_DIR="/mnt/SSD1/mrepos/github.com/wilsonify/nemo-git-integration/nemo-git-integration"
  SCRIPT="$TEST_DIR/s03b-add.sh"
  cp "$SOURCE_DIR/s03-update/s03b-add.sh" "$SCRIPT"
  chmod +x "$SCRIPT"

  # Setup zenity mock with log
  ZENITY_LOG="$TEST_DIR/zenity_log.txt"
  export ZENITY_LOG

  export PATH="$TEST_DIR:$PATH"
  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity Mock] $@" >> "$ZENITY_LOG"
if [[ "$*" == *"--question"* ]]; then
  exit 0  # simulate "OK"
elif [[ "$*" == *"--error"* || "$*" == *"--warning"* ]]; then
  exit 1
fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  # Initialize git repo
  cd "$TEST_DIR"
  git config --global init.defaultBranch main
  git init
  echo "Hello" > file1.txt
  echo "World" > file2.txt
  git add .
  git commit -m "Initial commit"

  git reset HEAD file1.txt  # Unstage file1.txt correctly
  touch file3.txt           # New untracked file
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "adds selected files successfully and shows zenity info" {
  git reset  # Ensure clean staging area

  run "$SCRIPT" "$TEST_DIR" "file1.txt" "file3.txt"
  [ "$status" -eq 0 ]

  # ✅ Validate staging
  run git diff --cached --name-only
  echo "$output"
  [[ "$output" == *file1.txt* ]]
  [[ "$output" == *file3.txt* ]]

  # ✅ Validate zenity dialogs
  run grep -- "--question" "$ZENITY_LOG"
  run grep -- "--info" "$ZENITY_LOG"
}

@test "shows zenity error if target directory not accessible" {
  run "$SCRIPT" "/nonexistent/dir" "file1.txt"
  [ "$status" -ne 0 ]
  run grep -- "Directory Error" "$ZENITY_LOG"
}

@test "shows zenity error if not a git repository" {
  mkdir "$TEST_DIR/notagit"
  run "$SCRIPT" "$TEST_DIR/notagit" "file1.txt"
  [ "$status" -ne 0 ]
  run grep -- "Not a Git Repository" "$ZENITY_LOG"
}

@test "exits cleanly when user cancels add confirmation" {
  # Override zenity to simulate cancel
  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity Mock Cancel] $@" >> "$ZENITY_LOG"
if [[ "$*" == *"--question"* ]]; then
  exit 1  # simulate "Cancel"
fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"
  export ZENITY_LOG  # Re-export in case subshells don't inherit

  git reset  # Ensure clean staging area

  run "$SCRIPT" "$TEST_DIR" "file1.txt"
  [ "$status" -eq 0 ]

  run git diff --cached --name-only
  [[ "$output" != *file1.txt* ]]
}
