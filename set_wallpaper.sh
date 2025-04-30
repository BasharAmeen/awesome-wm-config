#!/bin/bash
# Script to set wallpaper for Awesome WM

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/.config/awesome/wallpapers"

# Create the directory if it doesn't exist
mkdir -p "$WALLPAPER_DIR"

# If a file is provided as an argument, copy it to the wallpaper directory
if [ -n "$1" ]; then
    if [ -f "$1" ]; then
        cp "$1" "$WALLPAPER_DIR/"
        echo "Copied $1 to $WALLPAPER_DIR"
        echo "Restart awesome or use the wallpaper menu to apply it"
    else
        echo "Error: $1 is not a valid file"
        exit 1
    fi
fi

# Show help if no arguments
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/image.jpg"
    echo "This will copy the image to $WALLPAPER_DIR"
    echo "Then restart awesome or use the wallpaper menu to apply it"
fi
