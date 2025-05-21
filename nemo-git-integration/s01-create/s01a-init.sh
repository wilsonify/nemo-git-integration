#!/bin/bash
cd "$1" || exit 1
if git init; then
    zenity --info --title="Git Init Success" --text="Initialized empty Git repository in:\n$PWD/.git"
else
    zenity --error --title="Git Init Failed" --text="Could not initialize Git repository."
fi
