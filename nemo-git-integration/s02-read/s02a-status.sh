#!/bin/bash

# Get the directory from the argument
TARGET_DIR="$1"

cd "$TARGET_DIR" || {
  zenity --error --title="Error" --text="Could not access directory: $TARGET_DIR"
  exit 1
}

# Check if the directory is a git repository
if [ ! -d ".git" ]; then
  zenity --error --title="Not a Git Repository" --text="'$TARGET_DIR' is not a Git repository."
  exit 1
fi

# Run git status and capture output
STATUS_OUTPUT=$(git status 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  zenity --error --title="Git Error" --text="git status failed:\n$STATUS_OUTPUT"
  exit $EXIT_CODE
fi

# Display the output in a scrollable text box
zenity --text-info \
  --title="Git Status: $(basename "$TARGET_DIR")" \
  --width=600 --height=400 \
  --filename=<(echo "$STATUS_OUTPUT")
