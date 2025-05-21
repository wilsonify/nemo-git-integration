#!/bin/bash
# Detect whether the last action was a branch creation or just a checkout to an existing branch.
# If a new branch was created, delete that branch.
# If the user switched branches, switch back to the previous branch.
# branch.sh records previous and new branch names.
# unbranch.sh reads those and safely reverts:
# Deletes the new branch if it was just created.
# Switches back to the previous branch.
# Warns or aborts if the current branch isn’t expected (to avoid data loss).

cd "$1" || exit 1

PREV_BRANCH_FILE="$HOME/.cache/nemo_git_prev_branch"
CUR_BRANCH_FILE="$HOME/.cache/nemo_git_current_branch"

if [ ! -f "$PREV_BRANCH_FILE" ] || [ ! -f "$CUR_BRANCH_FILE" ]; then
    zenity --error --title="Unbranch Error" --text="No branch state found to undo."
    exit 1
fi

PREV_BRANCH=$(cat "$PREV_BRANCH_FILE")
CUR_BRANCH=$(cat "$CUR_BRANCH_FILE")

CURRENT=$(git rev-parse --abbrev-ref HEAD)

if [ "$CURRENT" != "$CUR_BRANCH" ]; then
    zenity --warning --title="Branch Mismatch" --text="Current branch is $CURRENT, expected $CUR_BRANCH. Cannot safely undo."
    exit 1
fi

# Check if CUR_BRANCH existed before (excluding PREV_BRANCH)
EXISTED_BEFORE=$(git branch --list "$CUR_BRANCH")

if [ -z "$EXISTED_BEFORE" ]; then
    # Branch was newly created, delete it
    git checkout "$PREV_BRANCH"
    if git branch -D "$CUR_BRANCH"; then
        zenity --info --title="Unbranch" --text="Deleted newly created branch '$CUR_BRANCH' and switched back to '$PREV_BRANCH'."
    else
        zenity --error --title="Unbranch Error" --text="Failed to delete branch '$CUR_BRANCH'."
        exit 1
    fi
else
    # Branch existed before, just switch back
    git checkout "$PREV_BRANCH"
    zenity --info --title="Unbranch" --text="Switched back to previous branch '$PREV_BRANCH'."
fi

# Clean up state files
rm -f "$PREV_BRANCH_FILE" "$CUR_BRANCH_FILE"
