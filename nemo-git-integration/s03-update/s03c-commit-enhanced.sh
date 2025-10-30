#!/bin/bash

# Enhanced version of s03c-commit.sh that handles multiple repos
TARGET_DIR="$1"
shift
SELECTED_FILES=("$@")

# Function to check if a path is in a git repo and get the repo root
get_git_repo_root() {
    local path="$1"
    local dir="$path"
    
    # If it's a file, get its directory
    if [ -f "$path" ]; then
        dir="$(dirname "$path")"
    fi
    
    # Convert to absolute path
    dir="$(realpath "$dir")"
    
    # Walk up to find .git directory
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    
    return 1
}

# Group files by their git repository
declare -A repos_to_files
declare -A failed_files

for file in "${SELECTED_FILES[@]}"; do
    # Validate file path to prevent command injection (check for dangerous characters)
    if [[ "$file" =~ \$ ]] || [[ "$file" =~ \` ]] || [[ "$file" =~ \| ]] || [[ "$file" =~ \; ]] || [[ "$file" =~ \& ]]; then
        failed_files["$file"]="Invalid file path: contains potentially dangerous characters"
        continue
    fi
    
    if [ ! -e "$file" ]; then
        failed_files["$file"]="File does not exist"
        continue
    fi
    
    repo_root=$(get_git_repo_root "$file")
    if [ $? -eq 0 ]; then
        # Get relative path from repo root
        rel_path=$(realpath --relative-to="$repo_root" "$file")
        repos_to_files["$repo_root"]+="$rel_path "
    else
        failed_files["$file"]="Not in a git repository"
    fi
done

# Show failed files if any
if [ ${#failed_files[@]} -gt 0 ]; then
    failed_msg="Some files could not be processed:\n"
    for file in "${!failed_files[@]}"; do
        failed_msg+="$file: ${failed_files[$file]}\n"
    done
    zenity --warning --title="Git Commit - Some Files Failed" --text="$failed_msg"
fi

# Exit if no files in valid repos
if [ ${#repos_to_files[@]} -eq 0 ]; then
    zenity --error --title="Git Commit - No Valid Files" --text="No files are in valid git repositories."
    exit 1
fi

# Confirm selected files exist
total_files=0
for repo_root in "${!repos_to_files[@]}"; do
    files=${repos_to_files[$repo_root]}
    for file in $files; do
        ((total_files++))
    done
done

if [ $total_files -eq 0 ]; then
    zenity --error --title="No Files Selected" --text="Please select one or more files to commit."
    exit 1
fi

# Ask for commit message
COMMIT_MSG=$(zenity --entry --title="Git Commit" --text="Enter a commit message for $total_files files:")

# Exit if user cancels or leaves message empty
if [ -z "$COMMIT_MSG" ]; then
    zenity --warning --title="Empty Commit Message" --text="No commit message entered. Commit aborted."
    exit 1
fi

# Sanitize commit message to prevent command injection
COMMIT_MSG=$(echo "$COMMIT_MSG" | tr -d '\000\001\002\003\004\005\006\007\010\011\012\013\014\015\016\017\020\021\022\023\024\025\026\027\030\031\032\033\034\035\036\037\177')

# Process each repository
declare -A repo_results

for repo_root in "${!repos_to_files[@]}"; do
    cd "$repo_root" || {
        repo_results["$repo_root"]="Failed to access directory"
        continue
    }
    
    files=${repos_to_files[$repo_root]}
    
    # Stage the files
    staged_files=""
    failed_files_in_repo=""
    for file in $files; do
        if git add "$file" 2>/dev/null; then
            staged_files+="$file "
        else
            failed_files_in_repo+="$file "
        fi
    done
    
    # Commit the changes
    result_msg="Repository: $(basename "$repo_root")\n"
    if [ -n "$staged_files" ]; then
        if git commit -m "$COMMIT_MSG"; then
            result_msg+="Successfully committed: $staged_files\n"
        else
            result_msg+="Commit failed for: $staged_files\n"
        fi
    fi
    if [ -n "$failed_files_in_repo" ]; then
        result_msg+="Failed to stage: $failed_files_in_repo\n"
    fi
    
    repo_results["$repo_root"]="$result_msg"
done

# Show results
results_msg="Git Commit Results:\n\n"
for repo_root in "${!repo_results[@]}"; do
    results_msg+="${repo_results[$repo_root]}\n"
done

zenity --info --title="Commit Complete" --text="$results_msg"
