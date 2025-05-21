#!/bin/bash

TARGET_DIR="$1"
shift
SELECTED_FILES=("$@")

cd "$TARGET_DIR" || {
  zenity --error --title="Directory Error" --text="Cannot access: $TARGET_DIR"
  exit 1
}

# Check for Git repo
if [ ! -d ".git" ]; then
  zenity --error --title="Not a Git Repository" --text="This directory is not a Git repository."
  exit 1
fi

# Confirm selected files exist
if [ ${#SELECTED_FILES[@]} -eq 0 ]; then
  zenity --error --title="No Files Selected" --text="Please select one or more files to commit."
  exit 1
fi

# Stage the files
for FILE in "${SELECTED_FILES[@]}"; do
  git add "$FILE"
done

# Ask for commit message
COMMIT_MSG=$(zenity --entry --title="Git Commit" --text="Enter a commit message:")

# Exit if user cancels or leaves message empty
if [ -z "$COMMIT_MSG" ]; then
  zenity --warning --title="Empty Commit Message" --text="No commit message entered. Commit aborted."
  exit 1
fi

# Commit the changes
if git commit -m "$COMMIT_MSG"; then
  zenity --info --title="Commit Successful" --text="Your changes have been committed:\n\n$COMMIT_MSG"
else
  zenity --error --title="Commit Failed" --text="There was an error committing your changes."
fi
