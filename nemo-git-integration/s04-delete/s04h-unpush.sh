#!/bin/bash
# The inverse of a push.
# Force the remote branch to a previous state (git push --force).
# We can use HEAD~1 to remove the last pushed commit (or more).
# Must confirm with the user, as this is destructive.
# Optionally allow selection of how far to rewind (e.g., last 1 or 2 commits).
# Warning:
# This will rewrite history on the remote. It’s only safe:

TARGET_DIR="$1"
cd "$TARGET_DIR" || {
  zenity --error --title="Directory Error" --text="Cannot access: $TARGET_DIR"
  exit 1
}

# Validate Git repo
if [ ! -d .git ]; then
  zenity --error --title="Not a Git Repository" --text="This is not a Git repository."
  exit 1
fi

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check if branch has upstream
UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)
if [ -z "$UPSTREAM" ]; then
  zenity --error --title="No Upstream" --text="Branch '$BRANCH' has no upstream to unpush from."
  exit 1
fi

# Ask how many commits to rewind
NUM_COMMITS=$(zenity --entry --title="Undo Git Push" \
  --text="How many commits do you want to unpush from the remote?\nThis will *safely* rewrite history on the remote." \
  --entry-text="1")

# Validate input
if ! [[ "$NUM_COMMITS" =~ ^[0-9]+$ ]]; then
  zenity --error --title="Invalid Input" --text="Please enter a valid number of commits."
  exit 1
fi

# Confirm user intent
zenity --question --title="Confirm Unpush" \
  --text="This will remove the last $NUM_COMMITS commit(s) from remote '$UPSTREAM' using --force-with-lease.\nProceed?" || exit 0

# Perform safe force push
if git push --force-with-lease origin HEAD~"$NUM_COMMITS":refs/heads/"$BRANCH"; then
  zenity --info --title="Unpush Successful" --text="Last $NUM_COMMITS commit(s) removed from remote '$UPSTREAM'."
else
  zenity --error --title="Unpush Failed" --text="Unpush failed. The remote may have moved. Try again after fetching."
  exit 1
fi
