#!/bin/bash
# Create a new git branch or switch to an existing one

# Navigate to the given directory
cd "$1"
PREV_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Get the branch name
BRANCH_NAME=$(
    # List all local and remote branches. remove unwanted characters and lines via sed.
    # Create a drop-down list with an editable text entry.
    # Prompt for a new branch name

    (git branch -a | \
    sed -e "s/^..//" -e "s/remotes.origin.//" -e "s/*//" -e "/HEAD detached/d" | \
    sort -u && echo "[New Branch]"\
    ) | \
    zenity --list --editable \
    --text "Select an existing branch or type a new branch name:" \
    --title "Git Create/Switch Branch" \
    --column "Branches"
)

# Check if the branch name is provided

if [ -n "$BRANCH_NAME" ]; then
    # If the user chose to create a new branch
    if [ "$BRANCH_NAME" = "[New Branch]" ]; then
        BRANCH_NAME=$(zenity --entry --text "Enter the new branch name" --title "Git Create Branch")
        git checkout -b "$BRANCH_NAME"
        echo "$PREV_BRANCH" > ~/.cache/nemo_git_prev_branch
        echo "$BRANCH_NAME" > ~/.cache/nemo_git_current_branch

    else
      git checkout "$BRANCH_NAME"
      echo "$PREV_BRANCH" > ~/.cache/nemo_git_prev_branch
      echo "$BRANCH_NAME" > ~/.cache/nemo_git_current_branch
    fi


fi

