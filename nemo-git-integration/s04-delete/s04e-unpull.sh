#!/bin/bash

TARGET_DIR="$1"
STATE_DIR="$HOME/.cache/nemo_git_pull_state"

cd "$TARGET_DIR" || {
  zenity --error --title="Directory Error" --text="Cannot access: $TARGET_DIR"
  exit 1
}

if [ ! -d ".git" ]; then
  zenity --error --title="Not a Git Repository" --text="The folder is not a Git repository."
  exit 1
fi

if [ ! -d "$STATE_DIR" ]; then
  zenity --error --title="State Missing" --text="No pull state found to undo."
  exit 1
fi

PULL_HEAD_FILE="$STATE_DIR/head_before_pull"
STASHED_FILE="$STATE_DIR/was_stashed"

if [ ! -f "$PULL_HEAD_FILE" ]; then
  zenity --error --title="State Missing" --text="Missing saved HEAD commit hash."
  exit 1
fi

ORIGINAL_HEAD=$(cat "$PULL_HEAD_FILE")
WAS_STASHED=$(cat "$STASHED_FILE")

CURRENT_HEAD=$(git rev-parse HEAD)

if [ "$CURRENT_HEAD" = "$ORIGINAL_HEAD" ]; then
  zenity --info --title="Nothing to Undo" --text="Current HEAD matches saved state; no pull to undo."
  exit 0
fi

# Reset to original HEAD commit (undo pull)
git reset --hard "$ORIGINAL_HEAD"
if [ $? -ne 0 ]; then
  zenity --error --title="Reset Failed" --text="Failed to reset to $ORIGINAL_HEAD."
  exit 1
fi

# Restore stash if we stashed before
if [ "$WAS_STASHED" = "true" ]; then
  git stash apply
  if [ $? -eq 0 ]; then
    zenity --info --title="Unpull Success" --text="Reset to pre-pull state and restored stash."
  else
    zenity --warning --title="Unpull Warning" --text="Reset succeeded but failed to apply stash."
  fi
else
  zenity --info --title="Unpull Success" --text="Reset to pre-pull state."
fi

# Clean up state files
rm -rf "$STATE_DIR"
