#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  SOURCE_DIR="/mnt/SSD1/mrepos/github.com/wilsonify/nemo-git-integration/nemo-git-integration"
  SCRIPT_NAME="s01b-clone.sh"
  SCRIPT_PATH="$SOURCE_DIR/s01-create/$SCRIPT_NAME"

  cp "$SCRIPT_PATH" "$TEST_DIR/$SCRIPT_NAME"
  chmod +x "$TEST_DIR/$SCRIPT_NAME"

  export PATH="$TEST_DIR:$PATH"

  # Create mock zenity with dynamic entry injection
  cat > "$TEST_DIR/zenity" <<'EOF'
#!/bin/bash
if [[ "$*" == *"--entry"* ]]; then
  echo "$ZENITY_MOCK_REPO_URL"
  exit 0
elif [[ "$*" == *"--info"* ]]; then
  echo "[Zenity Info] $@" >&2
  exit 0
elif [[ "$*" == *"--error"* ]]; then
  echo "[Zenity Error] $@" >&2
  exit 1
elif [[ "$*" == *"--warning"* ]]; then
  echo "[Zenity Warning] $@" >&2
  exit 0
fi
EOF
  chmod +x "$TEST_DIR/zenity"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "s01b-clone.sh clones a repository successfully" {
  export ZENITY_MOCK_REPO_URL="https://github.com/wilsonify/nemo-git-integration.git"
  echo "$TEST_DIR"
  run "$TEST_DIR/$SCRIPT_NAME" "$TEST_DIR"

  [ "$status" -eq 0 ]
  [ -d "$TEST_DIR/nemo-git-integration" ]
  [ -d "$TEST_DIR/nemo-git-integration/.git" ]
}

@test "s01b-clone.sh shows error when no URL is entered" {
  export ZENITY_MOCK_REPO_URL=""

  run "$TEST_DIR/$SCRIPT_NAME" "$TEST_DIR"

  [ "$status" -eq 1 ]
  [ ! -d "$TEST_DIR/.git" ]
}

@test "s01b-clone.sh handles clone failure" {
  export ZENITY_MOCK_REPO_URL="https://invalid.url/fake/repo.git"

  run "$TEST_DIR/$SCRIPT_NAME" "$TEST_DIR"

  [ "$status" -ne 0 ] # Git clone should fail
}
