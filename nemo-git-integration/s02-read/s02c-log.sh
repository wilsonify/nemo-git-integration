#!/bin/bash

# Argument: target directory from Nemo (%P)
TARGET_DIR="$1"

cd "$TARGET_DIR" || {
  zenity --error --title="Directory Error" --text="Cannot access directory:\n$TARGET_DIR"
  exit 1
}

# Check for Git repository
if [ ! -d ".git" ]; then
  zenity --error --title="Not a Git Repo" --text="'$TARGET_DIR' is not a Git repository."
  exit 1
fi

# Create a formatted Git log
LOG_OUTPUT=$(git log \
  --graph \
  --decorate \
  --oneline \
  --simplify-by-decoration 2>&1)

EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
  zenity --error --title="Git Error" --text="git log failed:\n$LOG_OUTPUT"
  exit $EXIT_CODE
fi

# Show the Git log in a scrollable window
zenity --text-info \
  --title="Git Log: $(basename "$TARGET_DIR")" \
  --width=800 \
  --height=600 \
  --filename=<(echo "$LOG_OUTPUT")
