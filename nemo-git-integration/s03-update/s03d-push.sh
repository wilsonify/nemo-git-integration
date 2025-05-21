#!/bin/bash

TARGET_DIR="$1"
cd "$TARGET_DIR" || {
  zenity --error --title="Directory Error" --text="Cannot access: $TARGET_DIR"
  exit 1
}

# Ensure this is a git repo
if [ ! -d .git ]; then
  zenity --error --title="Not a Git Repository" --text="This directory is not a Git repository."
  exit 1
fi

# Get the current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check if upstream is set
UPSTREAM_SET=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)

# If upstream is not set, ask for remote
if [ -z "$UPSTREAM_SET" ]; then
  REMOTE=$(git remote)
  if [ -z "$REMOTE" ]; then
    zenity --error --title="No Remote" --text="No remote configured. Please add a remote before pushing."
    exit 1
  fi

  # Ask user to confirm setting upstream
  zenity --question --title="Set Upstream?" \
    --text="Upstream is not set for branch '$CURRENT_BRANCH'.\nDo you want to set it and push?"
  if [ $? -ne 0 ]; then
    zenity --info --title="Push Cancelled" --text="Push was cancelled."
    exit 0
  fi

  if git push --set-upstream "$REMOTE" "$CURRENT_BRANCH"; then
    zenity --info --title="Push Successful" --text="Branch '$CURRENT_BRANCH' pushed and upstream set."
  else
    zenity --error --title="Push Failed" --text="Failed to push and set upstream."
    exit 1
  fi
else
  if git push; then
    zenity --info --title="Push Successful" --text="Changes pushed to '$UPSTREAM_SET'."
  else
    zenity --error --title="Push Failed" --text="Failed to push to '$UPSTREAM_SET'."
    exit 1
  fi
fi
