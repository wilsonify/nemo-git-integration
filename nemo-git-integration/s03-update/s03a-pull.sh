#!/bin/bash

TARGET_DIR="$1"

# Step 1: Navigate
cd "$TARGET_DIR" || {
  zenity --error --title="Directory Error" --text="Cannot access: $TARGET_DIR"
  exit 1
}

# Step 2: Validate Git repo
if [ ! -d ".git" ]; then
  zenity --error --title="Not a Git Repository" --text="The folder is not a Git repository."
  exit 1
fi

# Step 3: Ask to stash (only if needed)
if [[ -n $(git status --porcelain) ]]; then
  zenity --question --title="Uncommitted Changes" \
    --text="You have local changes. Stash before pulling?" || exit 0
  STASH_BEFORE=true
else
  STASH_BEFORE=false
fi

# Step 4: Fetch from remote
FETCH_MSG=$(git fetch 2>&1)
if [ $? -ne 0 ]; then
  zenity --error --title="Git Fetch Failed" --text="$FETCH_MSG"
  exit 1
fi

# Step 5: Stash if needed
if $STASH_BEFORE; then
  STASH_MSG=$(git stash push -u 2>&1)
  if [ $? -ne 0 ]; then
    zenity --error --title="Stash Failed" --text="$STASH_MSG"
    exit 1
  fi
fi

# Step 6: Pull with rebase
mkdir -p "$HOME/.cache/nemo_git_pull_state"
git rev-parse HEAD > "$HOME/.cache/nemo_git_pull_state/head_before_pull"
echo "$STASH_BEFORE" > "$HOME/.cache/nemo_git_pull_state/was_stashed"
PULL_MSG=$(git pull --rebase 2>&1)
PULL_EXIT=$?

# Step 7: Restore stash if it was pushed
if $STASH_BEFORE; then
  STASH_POP_MSG=$(git stash pop 2>&1)
fi

# Step 8: Show results
if [ $PULL_EXIT -eq 0 ]; then
  zenity --info --title="Git Pull Successful" --text="$PULL_MSG"
else
  zenity --error --title="Git Pull Error" --text="$PULL_MSG"
  exit $PULL_EXIT
fi
