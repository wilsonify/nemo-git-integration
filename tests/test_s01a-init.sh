#!/usr/bin/env bats

# Setup: create a temp dir
setup() {
  TEST_DIR=$(mktemp -d)
  SOURCE_DIR="/mnt/SSD1/mrepos/github.com/wilsonify/nemo-git-integration/nemo-git-integration"
  SCRIPT_NAME="s01a-init.sh"
  SCRIPT_PATH="$SOURCE_DIR/s01-create/$SCRIPT_NAME"

  # Provide clean path in test dir
  cp "$SCRIPT_PATH" "$TEST_DIR/$SCRIPT_NAME"
  chmod +x "$TEST_DIR/$SCRIPT_NAME"

  # Mock zenity
  export PATH="$TEST_DIR:$PATH"
  cat > "$TEST_DIR/zenity" <<'EOF'
#!/bin/bash
echo "[Zenity Mock] $@" >&2
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"
}

# Teardown: remove the temp dir
teardown() {
  rm -rf "$TEST_DIR"
}

@test "s01a-init.sh initializes a git repository successfully" {
  # Act
  run "$TEST_DIR/$SCRIPT_NAME" "$TEST_DIR"

  # Assert return code and side effects
  [ "$status" -eq 0 ]
  [ -d "$TEST_DIR/.git" ]

  # Assert the Git repo is really initialized
  git -C "$TEST_DIR" rev-parse --is-inside-work-tree | grep -q "true"
}

@test "s01a-init.sh fails on invalid path" {
  INVALID_DIR="/nonexistent/path/to/repo"
  run "$TEST_DIR/$SCRIPT_NAME" "$INVALID_DIR"

  # The script should exit with a failure code
  [ "$status" -ne 0 ]
  # No .git directory should be created
  [ ! -d "$INVALID_DIR/.git" ]
}
