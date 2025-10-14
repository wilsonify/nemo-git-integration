#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  SCRIPT="$TEST_DIR/s04d-unbranch.sh"
  SOURCE_DIR="${BATS_TEST_DIRNAME}/../nemo-git-integration"
  cp "$SOURCE_DIR/s04-delete/s04d-unbranch.sh" "$SCRIPT"
  chmod +x "$SCRIPT"

  # Init repo
  cd "$TEST_DIR"
  git init > /dev/null
  echo "first" > file.txt
  git add file.txt && git commit -m "init" > /dev/null

  # Add Zenity mock
  export ZENITY_LOG="$TEST_DIR/zenity_log.txt"
  export PATH="$TEST_DIR:$PATH"

  cat <<'EOF' > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity] $@" >> "$ZENITY_LOG"
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  export HOME="$TEST_DIR"  # Redirect ~/.cache
  mkdir -p "$HOME/.cache"

  chown -R $USER "$TEST_DIR"

}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "deletes a newly created branch and switches back" {
  git checkout -b feature > /dev/null
  echo "new stuff" > file.txt
  git commit -am "change" > /dev/null

  echo "main" > "$HOME/.cache/nemo_git_prev_branch"
  echo "feature" > "$HOME/.cache/nemo_git_current_branch"

  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  run git branch --list feature
  run git rev-parse --abbrev-ref HEAD
  [ "$output" = "main" ]
}

@test "switches back to existing branch without deleting" {
  git checkout -b dev > /dev/null
  git checkout main > /dev/null
  git checkout dev > /dev/null

  echo "main" > "$HOME/.cache/nemo_git_prev_branch"
  echo "dev" > "$HOME/.cache/nemo_git_current_branch"

  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 0 ]
  run git rev-parse --abbrev-ref HEAD
  [ "$output" = "main" ]
  run git branch --list dev
  [[ "$output" == *"dev"* ]]  # Not deleted
}

@test "fails if branch state files are missing" {
  rm -f "$HOME/.cache/nemo_git_prev_branch" "$HOME/.cache/nemo_git_current_branch"
  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  run grep -- "Unbranch Error" "$ZENITY_LOG"
}

@test "fails if current branch != recorded current" {
  git checkout -b experimental > /dev/null
  echo "dev" > "$HOME/.cache/nemo_git_prev_branch"
  echo "feature" > "$HOME/.cache/nemo_git_current_branch"

  run "$SCRIPT" "$TEST_DIR"
  [ "$status" -eq 1 ]
  run grep -- "Branch Mismatch" "$ZENITY_LOG"
}

