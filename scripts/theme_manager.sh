#!/bin/bash

# theme_manager.sh
# A simple wrapper script for set_theme.sh with more user-friendly options
# Created: $(date)

# Set up logging
LOG_FILE="$HOME/.config/awesome/logs/theme_manager.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# Path to the main theme script
THEME_SCRIPT="$HOME/.config/awesome/scripts/set_theme.sh"

# Check if the main script exists
if [ ! -f "$THEME_SCRIPT" ]; then
    log "Error: Theme script not found: $THEME_SCRIPT"
    exit 1
fi

# Function to save a named theme
save_named_theme() {
    local theme_name="$1"
    
    if [ -z "$theme_name" ]; then
        log "Error: No theme name provided"
        echo "Usage: $0 save <theme_name>"
        exit 1
    fi
    
    # Save current theme
    "$THEME_SCRIPT" --save
    
    # Create named themes directory if it doesn't exist
    THEMES_DIR="$HOME/.config/awesome/themes/settings/themes"
    mkdir -p "$THEMES_DIR"
    
    # Copy the current theme to a named theme file
    cp "$HOME/.config/awesome/themes/settings/current_theme.conf" "$THEMES_DIR/${theme_name}.conf"
    
    log "Theme saved as: $theme_name"
}

# Function to apply a named theme
apply_named_theme() {
    local theme_name="$1"
    
    if [ -z "$theme_name" ]; then
        log "Error: No theme name provided"
        echo "Usage: $0 apply <theme_name>"
        exit 1
    fi
    
    # Check if the named theme exists
    THEME_FILE="$HOME/.config/awesome/themes/settings/themes/${theme_name}.conf"
    if [ ! -f "$THEME_FILE" ]; then
        log "Error: Theme not found: $theme_name"
        exit 1
    fi
    
    # Copy the named theme to the current theme file
    cp "$THEME_FILE" "$HOME/.config/awesome/themes/settings/current_theme.conf"
    
    # Apply the theme
    "$THEME_SCRIPT" --apply
    
    log "Theme applied: $theme_name"
}

# Function to list all saved themes
list_themes() {
    THEMES_DIR="$HOME/.config/awesome/themes/settings/themes"
    
    if [ ! -d "$THEMES_DIR" ]; then
        log "No themes directory found. Save a theme first."
        exit 1
    fi
    
    echo "Available themes:"
    for theme_file in "$THEMES_DIR"/*.conf; do
        if [ -f "$theme_file" ]; then
            theme_name=$(basename "$theme_file" .conf)
            echo "  - $theme_name"
        fi
    done
}

# Function to show the current theme details
show_current_theme() {
    "$THEME_SCRIPT" --show
}

# Main program
case "$1" in
    save)
        save_named_theme "$2"
        ;;
    apply)
        apply_named_theme "$2"
        ;;
    list)
        list_themes
        ;;
    show)
        show_current_theme
        ;;
    *)
        echo "Usage: $0 [COMMAND] [OPTIONS]"
        echo "Commands:"
        echo "  save <theme_name>    Save current theme settings with a name"
        echo "  apply <theme_name>   Apply a saved theme"
        echo "  list                 List all saved themes"
        echo "  show                 Show current theme settings"
        exit 1
        ;;
esac

exit 0 