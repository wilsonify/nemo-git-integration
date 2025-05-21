#!/bin/bash

# Get target directory from Nemo (%P)
TARGET_DIR="$1"

# Step 1: Validate directory
cd "$TARGET_DIR" || {
  zenity --error --title="Directory Error" --text="Cannot access directory:\n$TARGET_DIR"
  exit 1
}

# Step 2: Check for Git repository
if [ ! -d ".git" ]; then
  zenity --error --title="Not a Git Repo" --text="'$TARGET_DIR' is not a Git repository."
  exit 1
fi

# Step 3: List remotes
REMOTES=$(git remote)
if [ -z "$REMOTES" ]; then
  zenity --error --title="No Remotes" --text="No Git remotes found in this repository."
  exit 1
fi

REMOTE=$(echo "$REMOTES" | zenity --list \
  --title="Select Remote" \
  --text="Choose the remote to fetch from:" \
  --column="Remote" \
  --width=300 --height=200)

if [ -z "$REMOTE" ]; then
  zenity --info --title="Cancelled" --text="No remote selected. Fetch aborted."
  exit 0
fi

# Step 4: Perform fetch and capture output
FETCH_OUTPUT=$(git fetch "$REMOTE" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  zenity --info --title="Fetch Complete" --text="Fetched from '$REMOTE' successfully."
else
  zenity --error --title="Git Fetch Error" --text="Failed to fetch from '$REMOTE':\n$FETCH_OUTPUT"
  exit $EXIT_CODE
fi
