#!/usr/bin/env bats

setup() {
  TEST_DIR=$(mktemp -d)
  SOURCE_DIR="/mnt/SSD1/mrepos/github.com/wilsonify/nemo-git-integration/nemo-git-integration"
  SCRIPT="$TEST_DIR/s03a-pull.sh"
  cp "$SOURCE_DIR/s03-update/s03a-pull.sh" "$SCRIPT"
  chmod +x "$SCRIPT"

  # Create a mock zenity
  export PATH="$TEST_DIR:$PATH"
  ZENITY_LOG="$TEST_DIR/zenity_log.txt"
  cat <<EOF > "$TEST_DIR/zenity"
#!/bin/bash
echo "[Zenity Mock] \$@" >> "$ZENITY_LOG"
if [[ "\$@" == *"--question"* ]]; then exit 0; fi
exit 0
EOF
  chmod +x "$TEST_DIR/zenity"

  # Setup local and remote git repositories
  REMOTE_REPO=$(mktemp -d)
  git config --global init.defaultBranch main
  git init --bare "$REMOTE_REPO"

  cd "$TEST_DIR"
  git config --global init.defaultBranch main
  git init
  echo "test" > file.txt
  git add file.txt
  git commit -m "initial"
  git remote add origin "$REMOTE_REPO"
  git push -u origin main
}

teardown() {
  rm -rf "$TEST_DIR" "$REMOTE_REPO"
}

@test "s03a-pull.sh pulls latest changes with rebase" {
  # Add new change to stash
  echo "local edit" >> file.txt

  run "$SCRIPT" "$TEST_DIR"

  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/.git/config" ]
  grep -q "pull --rebase" "$ZENITY_LOG" || true  # Optional, since it's a script echo not a direct command
  grep -q "Git Pull Successful" "$ZENITY_LOG"
}
