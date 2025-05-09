#!/bin/bash

# set_hidpi.sh - Script to set HiDPI scaling for 4K displays
# Usage: ./set_hidpi.sh [dpi_value]
# If no dpi_value is provided, it defaults to 192 (2x scaling on a standard 96 DPI)

# Default DPI value (2x scaling)
DPI=${1:-192}

# Log file for debugging
LOG_FILE="$HOME/.config/awesome/hidpi_scaling.log"

echo "$(date): Setting DPI to $DPI" > "$LOG_FILE"

# Set the Xft.dpi X resource
echo "Xft.dpi: $DPI" | xrdb -merge

# Update GDK scaling if needed
export GDK_SCALE=2
export GDK_DPI_SCALE=0.5

# For Qt applications
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_SCALE_FACTOR=2

# Update Awesome's DPI by restarting it
echo "Restarting Awesome to apply DPI changes..." >> "$LOG_FILE"
echo "awesome.restart()" | awesome-client 2>> "$LOG_FILE"

echo "HiDPI scaling has been set to $DPI. Changes should take effect immediately."
echo "If you don't see the changes, try logging out and back in."

exit 0 