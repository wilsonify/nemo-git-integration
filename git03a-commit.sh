#!/bin/bash
# Iterate over all selected files and add them to the staging area
for FILE in "$@"; do
  git commit -m "modified $(basename "$FILE")"
done
