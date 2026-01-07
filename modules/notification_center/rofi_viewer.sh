#!/bin/bash

# notification_history.sh - Rofi-based notification history viewer
# Reads from ~/.config/awesome/data/notifications/history.json

# Reads from provided file path or default
# Usage: ./rofi_viewer.sh [path/to/history.json]

HISTORY_FILE="${1:-$HOME/.config/awesome/data/notifications/history.json}"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    notify-send "Error" "jq is required. Install with: sudo pacman -S jq"
    exit 1
fi

# Check if history file exists
if [ ! -f "$HISTORY_FILE" ]; then
    notify-send "Notification History" "No notifications yet"
    exit 0
fi

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    notify-send "Error" "rofi is required. Install with: sudo pacman -S rofi"
    exit 1
fi

# Parse notifications and format for rofi
get_notifications() {
    jq -r '.[] | "\(.timestamp | split("T")[0]) \(.timestamp | split("T")[1] | split(":")[0:2] | join(":")) | \(.app_name): \(.title) - \(.text | gsub("\n"; " ") | .[0:80])"' "$HISTORY_FILE" 2>/dev/null | tac
}

# Get notification count
COUNT=$(jq '. | length' "$HISTORY_FILE" 2>/dev/null || echo "0")

if [ "$COUNT" = "0" ]; then
    notify-send "Notification History" "No notifications"
    exit 0
fi

# Show rofi with notifications
SELECTED=$(get_notifications | rofi -dmenu \
    -i \
    -p "Notifications ($COUNT)" \
    -theme-str 'window { width: 650px; }' \
    -theme-str 'listview { lines: 12; }' \
    -mesg "Enter: Copy | Type to search")

# If user selected something, copy it silently
if [ -n "$SELECTED" ]; then
    # Try multiple clipboard methods
    if command -v xsel &> /dev/null; then
        printf '%s' "$SELECTED" | xsel --clipboard --input
    elif command -v xclip &> /dev/null; then
        printf '%s' "$SELECTED" | xclip -selection clipboard
    fi
fi
