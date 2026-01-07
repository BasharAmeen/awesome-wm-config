#!/bin/bash
# Wayland screenshot script using grim + slurp
# This is a Flameshot alternative that works natively on Wayland

# Take a screenshot of selected area
grim -g "$(slurp)" - | wl-copy
grim -g "$(slurp)" ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png

# Show notification
notify-send "Screenshot" "Saved to ~/Pictures and copied to clipboard"
