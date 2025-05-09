#!/bin/bash

# set_theme.sh
# Script to save and apply system theme settings
# Created: $(date)

# Set up logging
LOG_FILE="$HOME/.config/awesome/logs/theme_settings.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# Function to save current theme settings
save_theme() {
    log "Saving current theme settings..."
    
    # Create theme settings directory if it doesn't exist
    THEME_DIR="$HOME/.config/awesome/themes/settings"
    mkdir -p "$THEME_DIR"
    
    # Save settings to file
    SETTINGS_FILE="$THEME_DIR/current_theme.conf"
    
    {
        echo "# Theme settings saved on $(date)"
        echo "GTK_THEME=\"$(gsettings get org.gnome.desktop.interface gtk-theme)\""
        echo "COLOR_SCHEME=\"$(gsettings get org.gnome.desktop.interface color-scheme)\""
        echo "ICON_THEME=\"$(gsettings get org.gnome.desktop.interface icon-theme)\""
        echo "CURSOR_THEME=\"$(gsettings get org.gnome.desktop.interface cursor-theme)\""
        echo "FONT_NAME=\"$(gsettings get org.gnome.desktop.interface font-name)\""
        echo "TEXT_SCALING_FACTOR=\"$(gsettings get org.gnome.desktop.interface text-scaling-factor)\""
    } > "$SETTINGS_FILE"
    
    log "Theme settings saved to $SETTINGS_FILE"
}

# Function to apply saved theme settings
apply_theme() {
    log "Applying saved theme settings..."
    
    SETTINGS_FILE="$HOME/.config/awesome/themes/settings/current_theme.conf"
    
    # Check if settings file exists
    if [ ! -f "$SETTINGS_FILE" ]; then
        log "Error: Theme settings file not found: $SETTINGS_FILE"
        log "Please run with --save first to create the settings file."
        exit 1
    fi
    
    # Source the settings file
    # shellcheck source=/dev/null
    source "$SETTINGS_FILE"
    
    # Apply settings using gsettings
    gsettings set org.gnome.desktop.interface gtk-theme "${GTK_THEME//\'}"
    gsettings set org.gnome.desktop.interface color-scheme "${COLOR_SCHEME//\'}"
    gsettings set org.gnome.desktop.interface icon-theme "${ICON_THEME//\'}"
    gsettings set org.gnome.desktop.interface cursor-theme "${CURSOR_THEME//\'}"
    gsettings set org.gnome.desktop.interface font-name "${FONT_NAME//\'}"
    gsettings set org.gnome.desktop.interface text-scaling-factor "${TEXT_SCALING_FACTOR}"
    
    log "Theme settings applied successfully."
}

# Function to display current theme settings
show_theme() {
    log "Current theme settings:"
    
    echo "GTK Theme: $(gsettings get org.gnome.desktop.interface gtk-theme)"
    echo "Color Scheme: $(gsettings get org.gnome.desktop.interface color-scheme)"
    echo "Icon Theme: $(gsettings get org.gnome.desktop.interface icon-theme)"
    echo "Cursor Theme: $(gsettings get org.gnome.desktop.interface cursor-theme)"
    echo "Font: $(gsettings get org.gnome.desktop.interface font-name)"
    echo "Text Scaling Factor: $(gsettings get org.gnome.desktop.interface text-scaling-factor)"
}

# Main program
case "$1" in
    --save)
        save_theme
        ;;
    --apply)
        apply_theme
        ;;
    --show)
        show_theme
        ;;
    *)
        echo "Usage: $0 [OPTION]"
        echo "Options:"
        echo "  --save   Save current theme settings"
        echo "  --apply  Apply saved theme settings"
        echo "  --show   Show current theme settings"
        exit 1
        ;;
esac

exit 0 