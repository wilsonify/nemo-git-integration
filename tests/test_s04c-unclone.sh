#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  SOURCE_DIR="${BATS_TEST_DIRNAME}/../nemo-git-integration"
  SCRIPT="$TEST_DIR/s04c-unclone.sh"
  cp "$SOURCE_DIR/s04-delete/s04c-unclone.sh" "$SCRIPT"
  chmod +x "$SCRIPT"

  export ZENITY_LOG="$TEST_DIR/zenity_log.txt"
  export PATH="$TEST_DIR:$PATH"

  # Default Zenity mock behavior (simulate selection and confirmation)
  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity] $@" >> "$ZENITY_LOG"
if [[ "$*" == *"--file-selection"* ]]; then
  echo "$CLONED_REPO"  # Simulate selecting a directory
elif [[ "$*" == *"--question"* ]]; then
  exit 0  # Simulate "Yes"
elif [[ "$*" == *"--error"* || "$*" == *"--warning"* ]]; then
  exit 1
fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  # Simulate a cloned repo
  CLONED_REPO="$TEST_DIR/example-repo"
  export CLONED_REPO
  mkdir "$CLONED_REPO"
  cd "$CLONED_REPO"
  git init > /dev/null
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "successfully un-clones a selected git repo" {
  [ -d "$CLONED_REPO/.git" ]

  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ ! -d "$CLONED_REPO" ]

  run grep -- "--file-selection" "$ZENITY_LOG"
  run grep -- "--question" "$ZENITY_LOG"
  run grep -- "Unclone Success" "$ZENITY_LOG"
}

@test "shows error if DEST directory is not accessible" {
  run "$SCRIPT" "/nonexistent/path"
  [ "$status" -ne 0 ]
  run grep -- "Directory Error" "$ZENITY_LOG"
}

@test "cancels if user does not select a directory" {
  # Override zenity to simulate cancel
  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity Cancel] $@" >> "$ZENITY_LOG"
if [[ "$*" == *"--file-selection"* ]]; then
  echo ""  # Simulate cancel
  exit 0
fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  run grep -- "Unclone Cancelled" "$ZENITY_LOG"
  [ -d "$CLONED_REPO" ]
}

@test "warns if selected directory is not a git repo" {
  NON_GIT="$TEST_DIR/not-a-repo"
  mkdir "$NON_GIT"
  export CLONED_REPO="$NON_GIT"

  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -ne 0 ]
  run grep -- "Not a Git Repo" "$ZENITY_LOG"
}

@test "cancels if user declines deletion confirmation" {
  # Simulate confirmation cancel
  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity Decline] $@" >> "$ZENITY_LOG"
if [[ "$*" == *"--file-selection"* ]]; then
  echo "$CLONED_REPO"
elif [[ "$*" == *"--question"* ]]; then
  exit 1  # Simulate "No"
fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ -d "$CLONED_REPO" ]
  run grep -- "Cancelled" "$ZENITY_LOG"
}

@test "shows error if deletion fails" {
  chmod -w "$CLONED_REPO"  # Simulate permission error

  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -ne 0 ]
  run grep -- "Unclone Failed" "$ZENITY_LOG"

  chmod +w "$CLONED_REPO"  # Restore permission for cleanup
}
