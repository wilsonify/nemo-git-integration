#!/bin/bash

# Enhanced version of s03b-add.sh that handles multiple repos
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
    zenity --warning --title="Git Add - Some Files Failed" --text="$failed_msg"
fi

# Exit if no files in valid repos
if [ ${#repos_to_files[@]} -eq 0 ]; then
    zenity --error --title="Git Add - No Valid Files" --text="No files are in valid git repositories."
    exit 1
fi

# Confirm intent
total_files=0
for repo_root in "${!repos_to_files[@]}"; do
    files=${repos_to_files[$repo_root]}
    for file in $files; do
        ((total_files++))
    done
done

zenity --question --title="Git Add" --text="Add $total_files selected files to staging in their respective repositories?" || exit 0

# Process each repository
declare -A repo_results

for repo_root in "${!repos_to_files[@]}"; do
    cd "$repo_root" || {
        repo_results["$repo_root"]="Failed to access directory"
        continue
    }
    
    files=${repos_to_files[$repo_root]}
    added_files=""
    failed_files_in_repo=""
    
    for file in $files; do
        if git add "$file" 2>/dev/null; then
            added_files+="$file\n"
        else
            failed_files_in_repo+="$file "
        fi
    done
    
    result_msg="Repository: $(basename "$repo_root")\n"
    if [ -n "$added_files" ]; then
        result_msg+="Successfully staged:\n$added_files"
    fi
    if [ -n "$failed_files_in_repo" ]; then
        result_msg+="Failed to add: $failed_files_in_repo\n"
    fi
    
    repo_results["$repo_root"]="$result_msg"
done

# Show results
results_msg="Git Add Results:\n\n"
for repo_root in "${!repo_results[@]}"; do
    results_msg+="${repo_results[$repo_root]}\n"
done

zenity --info --title="Git Add Complete" --text="$results_msg"
