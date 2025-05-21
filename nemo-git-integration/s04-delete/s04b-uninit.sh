#!/bin/bash
# Confirm the directory is a Git repo.
# Confirm the user wants to delete .git.
# Safely remove .git, with a backup option if desired.
# Provide clear feedback.

TARGET_DIR="$1"
cd "$TARGET_DIR" || {
  zenity --error --title="Directory Error" --text="Cannot access: $TARGET_DIR"
  exit 1
}

# Safety check: is this actually a Git repository?
if [ ! -d ".git" ]; then
  zenity --warning --title="No Git Repo" --text="This directory is not a Git repository."
  exit 1
fi

# Confirm destructive action
zenity --question --title="Confirm Uninit" \
  --text="This will permanently delete the .git directory in:\n$PWD\n\nAll Git history will be lost.\n\nDo you want to continue?"

if [ $? -ne 0 ]; then
  zenity --info --title="Uninit Cancelled" --text="No changes were made."
  exit 0
fi

# Attempt to delete the .git directory
if rm -rf ".git"; then
  zenity --info --title="Git Uninit Success" \
    --text="Removed .git directory.\nThis directory is no longer a Git repository."
else
  zenity --error --title="Git Uninit Failed" \
    --text="Could not remove the .git directory."
  exit 1
fi
