#!/bin/bash

TARGET_DIR="$1"
shift
cd "$TARGET_DIR" || {
  zenity --error --title="Directory Error" --text="Cannot access: $TARGET_DIR"
  exit 1
}

# Ensure it's a Git repo
if [ ! -d .git ]; then
  zenity --error --title="Not a Git Repository" --text="This directory is not a Git repository."
  exit 1
fi

# Confirm destructive action
zenity --question --title="Confirm Reset" \
  --text="This will discard **local changes** to the selected files.\n\nDo you want to continue?"

if [ $? -ne 0 ]; then
  zenity --info --title="Reset Cancelled" --text="No changes were made."
  exit 0
fi

# Attempt to restore each selected file
ERRORS=()
for FILE in "$@"; do
  if git restore "$FILE" 2>/dev/null; then
    echo "Restored $FILE"
  else
    ERRORS+=("$FILE")
  fi
done

if [ ${#ERRORS[@]} -eq 0 ]; then
  zenity --info --title="Restore Complete" --text="All selected files were restored."
else
  zenity --error --title="Restore Incomplete" \
    --text="Some files could not be restored:\n\n${ERRORS[*]}"
fi
