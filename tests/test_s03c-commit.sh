#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  SOURCE_DIR="/mnt/SSD1/mrepos/github.com/wilsonify/nemo-git-integration/nemo-git-integration"
  SCRIPT="$TEST_DIR/s03c-commit.sh"
  cp "$SOURCE_DIR/s03-update/s03c-commit.sh" "$SCRIPT"
  chmod +x "$SCRIPT"

  # Setup zenity mock with log
  ZENITY_LOG="$TEST_DIR/zenity_log.txt"
  export ZENITY_LOG

  export PATH="$TEST_DIR:$PATH"
  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity Mock] $@" >> "$ZENITY_LOG"
if [[ "$*" == *"--entry"* ]]; then
  echo "Test commit message"
  exit 0
elif [[ "$*" == *"--error"* || "$*" == *"--warning"* ]]; then
  exit 1
fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  # Initialize Git repo
  cd "$TEST_DIR"
  git config --global init.defaultBranch main
  git init
  echo "A" > tracked.txt
  git add tracked.txt
  git commit -m "Initial commit"
  echo "update" >> tracked.txt
  echo "B" > newfile.txt
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "commits selected files successfully" {
  run "$SCRIPT" "$TEST_DIR" "tracked.txt" "newfile.txt"
  [ "$status" -eq 0 ]

  run git log --oneline -n 1
  [[ "$output" == *"Test commit message"* ]]

  run grep -- "--entry" "$ZENITY_LOG"
  run grep -- "--info" "$ZENITY_LOG"
}

@test "shows zenity error if target directory not accessible" {
  run "$SCRIPT" "/nonexistent/dir" "tracked.txt"
  [ "$status" -ne 0 ]
  run grep -- "Directory Error" "$ZENITY_LOG"
}

@test "shows zenity error if not a git repository" {
  mkdir "$TEST_DIR/notagit"
  run "$SCRIPT" "$TEST_DIR/notagit" "tracked.txt"
  [ "$status" -ne 0 ]
  run grep -- "Not a Git Repository" "$ZENITY_LOG"
}

@test "shows zenity error if no files selected" {
  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -ne 0 ]
  run grep -- "No Files Selected" "$ZENITY_LOG"
}

@test "aborts on empty commit message" {
  # Override zenity to simulate empty entry
  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity Mock Empty] $@" >> "$ZENITY_LOG"
if [[ "$*" == *"--entry"* ]]; then
  echo ""  # Simulate empty input
  exit 0
fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  run "$SCRIPT" "$TEST_DIR" "tracked.txt"
  [ "$status" -ne 0 ]
  run grep -- "Empty Commit Message" "$ZENITY_LOG"
}

@test "handles git commit failure gracefully" {
  # Create invalid state by removing .git folder
  rm -rf "$TEST_DIR/.git"

  run "$SCRIPT" "$TEST_DIR" "tracked.txt"
  [ "$status" -ne 0 ]
  run grep -- "Not a Git Repository" "$ZENITY_LOG"
}
