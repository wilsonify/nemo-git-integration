#!/bin/bash

TARGET_DIR="$1"
shift
SELECTED_FILES=("$@")

# Step 1: Navigate
cd "$TARGET_DIR" || {
  zenity --error --title="Directory Error" --text="Cannot access: $TARGET_DIR"
  exit 1
}

# Step 2: Validate Git repo
if [ ! -d ".git" ]; then
  zenity --error --title="Not a Git Repository" --text="This is not a Git repository."
  exit 1
fi

# Step 3: Confirm intent
zenity --question --title="Git Add" --text="Add selected files to staging?" || exit 0

# Step 4: Run git add and collect output
ADDED_FILES=""
for file in "${SELECTED_FILES[@]}"; do
  if git add "$file" 2>/dev/null; then
    ADDED_FILES+="$file\n"
  else
    zenity --warning --title="Add Warning" --text="Failed to add: $file"
  fi
done

# Step 5: Show results
if [ -n "$ADDED_FILES" ]; then
  zenity --info --title="Git Add Successful" \
    --text="Staged the following files:\n$ADDED_FILES"
else
  zenity --warning --title="Nothing Added" --text="No files were successfully added."
fi
