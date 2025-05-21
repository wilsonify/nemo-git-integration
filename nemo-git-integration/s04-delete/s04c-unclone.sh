#!/bin/bash
# Detect what repo was cloned (ideally right after cloning).
# Track or guess the cloned directory (often inferred from the repo URL).
# Confirm with the user before deleting that folder.

DEST="$1"
cd "$DEST" || {
  zenity --error --title="Directory Error" --text="Cannot access: $DEST"
  exit 1
}

# Let the user pick the folder to delete
TARGET_DIR=$(zenity --file-selection --directory \
  --title="Select Cloned Repository to Remove" \
  --filename="$DEST/")

# Check if user cancelled
if [ -z "$TARGET_DIR" ]; then
  zenity --info --title="Unclone Cancelled" --text="No directory selected."
  exit 0
fi

# Confirm it's actually a Git repo
if [ ! -d "$TARGET_DIR/.git" ]; then
  zenity --warning --title="Not a Git Repo" --text="Selected directory is not a Git repository."
  exit 1
fi

# Final confirmation
zenity --question --title="Confirm Unclone" \
  --text="This will permanently delete the cloned Git repository:\n$TARGET_DIR\n\nAre you sure?"

if [ $? -ne 0 ]; then
  zenity --info --title="Cancelled" --text="No changes were made."
  exit 0
fi

# Delete the cloned directory
if rm -rf "$TARGET_DIR"; then
  zenity --info --title="Unclone Success" --text="Deleted:\n$TARGET_DIR"
else
  zenity --error --title="Unclone Failed" --text="Failed to remove:\n$TARGET_DIR"
  exit 1
fi
