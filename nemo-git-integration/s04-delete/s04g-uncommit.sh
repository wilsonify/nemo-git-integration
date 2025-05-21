#!/bin/bash
# It should undo the last commit only if it affects the selected files.
# We must be cautious not to lose uncommitted changes.
# The safest approach is to soft reset the last commit (git reset --soft HEAD~1), which moves HEAD back but leaves changes staged.
# Then, optionally, we can unstage only the selected files (or leave them staged, depending on UX).
# We can also display info about the commit message being undone.
# Confirm user intent before undoing.
# It checks if the last commit actually touches the selected files (avoiding undoing unrelated commits).
# It prompts the user before resetting.
# Uses git reset --soft HEAD~1 to undo the last commit without losing changes (changes stay staged).
# This approach assumes a single last commit to undo, matching the UX of your original commit script.

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
  zenity --error --title="No Files Selected" --text="Please select one or more files to uncommit."
  exit 1
fi

# Get the last commit hash and message
LAST_COMMIT_HASH=$(git log -1 --pretty=format:%H)
LAST_COMMIT_MSG=$(git log -1 --pretty=format:%s)

# Check if last commit includes selected files
FILES_IN_COMMIT=$(git diff-tree --no-commit-id --name-only -r "$LAST_COMMIT_HASH")

# Verify intersection with selected files
MATCH=false
for file in "${SELECTED_FILES[@]}"; do
  if echo "$FILES_IN_COMMIT" | grep -Fxq "$file"; then
    MATCH=true
    break
  fi
done

if ! $MATCH; then
  zenity --error --title="No Matching Commit" --text="The last commit does not include the selected files. Cannot uncommit safely."
  exit 1
fi

# Confirm undo
zenity --question --title="Confirm Undo Commit" \
  --text="Undo the last commit?\n\nCommit message:\n$LAST_COMMIT_MSG" || exit 0

# Soft reset the last commit
if git reset --soft HEAD~1; then
  zenity --info --title="Uncommit Successful" --text="Last commit has been undone.\nYour changes are now staged."
else
  zenity --error --title="Uncommit Failed" --text="Failed to undo the last commit."
  exit 1
fi
