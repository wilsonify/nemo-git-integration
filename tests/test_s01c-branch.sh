#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  SOURCE_DIR="/mnt/SSD1/mrepos/github.com/wilsonify/nemo-git-integration/nemo-git-integration"
  SCRIPT_NAME="s01c-branch.sh"
  SCRIPT_PATH="$SOURCE_DIR/s01-create/$SCRIPT_NAME"

  cp "$SCRIPT_PATH" "$TEST_DIR/$SCRIPT_NAME"
  chmod +x "$TEST_DIR/$SCRIPT_NAME"

  export PATH="$TEST_DIR:$PATH"

  # Create mock zenity
  cat > "$TEST_DIR/zenity" <<'EOF'
#!/bin/bash
if [[ "$*" == *"--list"* ]]; then
  echo "$ZENITY_BRANCH_SELECTION"
  exit 0
elif [[ "$*" == *"--entry"* ]]; then
  echo "$ZENITY_NEW_BRANCH_NAME"
  exit 0
fi
EOF
  chmod +x "$TEST_DIR/zenity"
}

teardown() {
  rm -rf "$TEST_DIR"
  rm -rf ~/.cache/nemo_git_*
}

@test "s01c-branch.sh creates a new branch" {
  cd "$TEST_DIR"
  git config --global init.defaultBranch main
  git init
  touch file.txt
  git add file.txt
  git commit -m "initial"

  export ZENITY_BRANCH_SELECTION="[New Branch]"
  export ZENITY_NEW_BRANCH_NAME="feature/test-branch"

  run "$TEST_DIR/s01c-branch.sh" "$TEST_DIR"

  [ "$status" -eq 0 ]
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  [ "$BRANCH" = "feature/test-branch" ]

  [ "$(cat ~/.cache/nemo_git_current_branch)" = "feature/test-branch" ]
  [ "$(cat ~/.cache/nemo_git_prev_branch)" = "main" ]
}

@test "s01c-branch.sh switches to an existing branch" {
  cd "$TEST_DIR"
  git config --global init.defaultBranch main
  git init >/dev/null
  touch file.txt
  git add file.txt
  git commit -m "initial" >/dev/null
  git checkout -b feature/other >/dev/null
  git checkout main >/dev/null

  export ZENITY_BRANCH_SELECTION="feature/other"

  run "$TEST_DIR/s01c-branch.sh" "$TEST_DIR"

  [ "$status" -eq 0 ]
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  [ "$BRANCH" = "feature/other" ]

  [ "$(cat ~/.cache/nemo_git_current_branch)" = "feature/other" ]
  [ "$(cat ~/.cache/nemo_git_prev_branch)" = "main" ]
}
