#!/bin/bash

# Required: Destination directory passed as $1
DEST="$1"

# Validate destination
if [ -z "$DEST" ] || [ ! -d "$DEST" ] || [ ! -w "$DEST" ]; then
  zenity --error --title="Invalid Destination" --text="Destination folder is not valid or writable:\n$DEST"
  exit 1
fi

# Prompt for Git repository URL
REPO_URL=$(zenity --entry --title="Git Clone" --text="Enter the Git repository URL:")

# Cancel check or empty input
if [ -z "$REPO_URL" ]; then
  zenity --error --title="No URL Entered" --text="You must enter a repository URL."
  exit 1
fi

# Derive folder name from URL
REPO_NAME=$(basename -s .git "$REPO_URL")
CLONE_PATH="$DEST/$REPO_NAME"

# Check if the target folder already exists
if [ -e "$CLONE_PATH" ]; then
  zenity --error --title="Clone Target Exists" --text="The folder already exists:\n$CLONE_PATH"
  exit 1
fi

# Perform clone
OUTPUT=$(git clone "$REPO_URL" "$CLONE_PATH" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  zenity --info --title="Clone Success" --text="Repository cloned successfully to:\n$CLONE_PATH"
else
  zenity --error --title="Clone Failed" --text="Git reported an error:\n$OUTPUT"
fi
