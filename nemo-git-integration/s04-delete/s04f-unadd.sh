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
zenity --question --title="Git Unstage" --text="Unstage selected files?" || exit 0

# Step 4: Run git restore --staged or git reset for each file and collect output
UNSTAGED_FILES=""
for file in "${SELECTED_FILES[@]}"; do
  if git restore --staged "$file" 2>/dev/null; then
    UNSTAGED_FILES+="$file\n"
  else
    # Fallback for older Git versions without 'git restore'
    if git reset "$file" 2>/dev/null; then
      UNSTAGED_FILES+="$file\n"
    else
      zenity --warning --title="Unstage Warning" --text="Failed to unstage: $file"
    fi
  fi
done

# Step 5: Show results
if [ -n "$UNSTAGED_FILES" ]; then
  zenity --info --title="Git Unstage Successful" \
    --text="Unstaged the following files:\n$UNSTAGED_FILES"
else
  zenity --warning --title="Nothing Unstaged" --text="No files were successfully unstaged."
fi
