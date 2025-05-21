#!/bin/bash
DEST="$1"
REPO_URL=$(zenity --entry --title="Git Clone" --text="Enter repository URL:")
if [ -n "$REPO_URL" ]; then
  cd "$DEST" && git clone "$REPO_URL"
  if [ $? -eq 0 ]; then
    zenity --info --title="Clone Success" --text="Repository cloned successfully."
  else
    zenity --error --title="Clone Failed" --text="Could not clone the repository."
  fi
else
  zenity --warning --title="No URL Entered" --text="You must enter a repository URL."
fi
