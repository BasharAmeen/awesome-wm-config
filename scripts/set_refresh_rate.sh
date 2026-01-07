#!/bin/bash

# set_refresh_rate.sh - Set screen refresh rate
# Usage: ./set_refresh_rate.sh

# Monitor: DP-4
# Mode: 1920x1080
# Rate: 143.98 Hz

xrandr --output DP-4 --mode 1920x1080 --rate 143.98

if [ $? -eq 0 ]; then
    echo "Refresh rate set to 143.98 Hz on DP-4"
else
    echo "Failed to set refresh rate"
    exit 1
fi
