#!/bin/bash

# Folder for saving (will be created automatically if it doesn't exist)
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

# Filename with date and time
FILE="$DIR/Screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png"

# Check the argument passed (area or full screen)
if [ "$1" == "area" ]; then
    # Take a screenshot of selected area (blue frame, semi-transparent background)
    grim -g "$(slurp -d -c 89b4fa -b 1e1e2e44 -w 2)" "$FILE"
elif [ "$1" == "screen" ]; then
    # Take a screenshot of the entire screen
    grim "$FILE"
else
    echo "Use argument 'area' or 'screen'"
    exit 1
fi

# Check if file was created (if you pressed Esc while selecting, there will be no file)
if [ -f "$FILE" ]; then
    # Copy image to clipboard
    wl-copy < "$FILE"

    # Send notification
    notify-send "Screenshot saved" "Copied to clipboard\nSaved to Screenshots folder"
fi
