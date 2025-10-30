#!/bin/bash

# Enhanced version of s02a-status.sh that handles directories with multiple repos

TARGET_DIR="$1"

# Function to check if a directory is a git repo
is_git_repo() {
    [ -d "$1/.git" ]
}

# Function to find all git repos in a directory
find_git_repos() {
    local search_dir="$1"
    local repos=()
    
    # Check if the directory itself is a git repo
    if is_git_repo "$search_dir"; then
        repos+=("$search_dir")
    else
        # Search for subdirectories that are git repos
        while IFS= read -r -d '' repo; do
            repos+=("$repo")
        done < <(find "$search_dir" -maxdepth 2 -type d -name ".git" -printf "%h\0" 2>/dev/null)
    fi
    
    printf '%s\n' "${repos[@]}"
}

# Function to show git status for a repo
show_repo_status() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")
    
    cd "$repo_path" || {
        echo "Error: Could not access directory: $repo_path"
        return 1
    }
    
    # Run git status and capture output
    STATUS_OUTPUT=$(git status 2>&1)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -ne 0 ]; then
        echo "Error in $repo_name: git status failed:\n$STATUS_OUTPUT"
        return $EXIT_CODE
    fi
    
    echo "=== Git Status: $repo_name ==="
    echo "$STATUS_OUTPUT"
    echo ""
}

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    zenity --error --title="Error" --text="Directory does not exist: $TARGET_DIR"
    exit 1
fi

# Find all git repositories
mapfile -t repos < <(find_git_repos "$TARGET_DIR")

if [ ${#repos[@]} -eq 0 ]; then
    zenity --error --title="Not a Git Repository" --text="'$TARGET_DIR' and its subdirectories are not Git repositories."
    exit 1
fi

# Generate status output for all repos
STATUS_OUTPUT=""
for repo in "${repos[@]}"; do
    STATUS_OUTPUT+=$(show_repo_status "$repo")
    STATUS_OUTPUT+=$'\n'
done

# Display the output in a scrollable text box
zenity --text-info \
  --title="Git Status: $(basename "$TARGET_DIR") (${#repos[@]} repositories)" \
  --width=800 --height=600 \
  --filename=<(echo -e "$STATUS_OUTPUT")
