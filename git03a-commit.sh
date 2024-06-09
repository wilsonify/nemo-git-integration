#!/bin/bash
# Iterate over all selected files and add them to the staging area
cd "$1"
shift
for FILE in "$@"; do
  git commit -m "modified $(basename "$FILE")"
done
