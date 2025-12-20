#!/bin/bash

# set_theme.sh
# Unified script to save, apply, and manage system theme settings

# Set up logging
LOG_FILE="$HOME/.config/awesome/logs/theme_settings.log"
log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

THEME_DIR="$HOME/.config/awesome/themes/settings"
THEMES_DIR="$THEME_DIR/themes"
SETTINGS_FILE="$THEME_DIR/current_theme.conf"

# Function to save current theme settings
save_theme() {
    log "Saving current theme settings..."
    mkdir -p "$THEME_DIR"
    
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
    
    if [ ! -f "$SETTINGS_FILE" ]; then
        log "Error: Theme settings file not found: $SETTINGS_FILE"
        log "Please run with --save first to create the settings file."
        exit 1
    fi
    
    # shellcheck source=/dev/null
    source "$SETTINGS_FILE"
    
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
    echo "Current theme settings:"
    echo "  GTK Theme: $(gsettings get org.gnome.desktop.interface gtk-theme)"
    echo "  Color Scheme: $(gsettings get org.gnome.desktop.interface color-scheme)"
    echo "  Icon Theme: $(gsettings get org.gnome.desktop.interface icon-theme)"
    echo "  Cursor Theme: $(gsettings get org.gnome.desktop.interface cursor-theme)"
    echo "  Font: $(gsettings get org.gnome.desktop.interface font-name)"
    echo "  Text Scaling: $(gsettings get org.gnome.desktop.interface text-scaling-factor)"
}

# Function to save as named theme
save_named() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "Error: Theme name required. Usage: $0 --save-as <name>"
        exit 1
    fi
    
    save_theme
    mkdir -p "$THEMES_DIR"
    cp "$SETTINGS_FILE" "$THEMES_DIR/${name}.conf"
    log "Theme saved as: $name"
}

# Function to apply named theme
apply_named() {
    local name="$1"
    if [ -z "$name" ]; then
        echo "Error: Theme name required. Usage: $0 --load <name>"
        exit 1
    fi
    
    local theme_file="$THEMES_DIR/${name}.conf"
    if [ ! -f "$theme_file" ]; then
        log "Error: Theme not found: $name"
        exit 1
    fi
    
    cp "$theme_file" "$SETTINGS_FILE"
    apply_theme
    log "Theme loaded: $name"
}

# Function to list saved themes
list_themes() {
    if [ ! -d "$THEMES_DIR" ]; then
        echo "No saved themes. Use --save-as <name> to create one."
        exit 0
    fi
    
    echo "Saved themes:"
    shopt -s nullglob
    for f in "$THEMES_DIR"/*.conf; do
        echo "  - $(basename "$f" .conf)"
    done
    shopt -u nullglob
}

# Show help
show_help() {
    echo "Usage: $0 [OPTION] [NAME]"
    echo ""
    echo "Options:"
    echo "  --save        Save current theme settings"
    echo "  --apply       Apply saved theme settings"
    echo "  --show        Show current theme settings"
    echo "  --save-as     Save current theme with a name"
    echo "  --load        Load and apply a named theme"
    echo "  --list        List all saved themes"
    echo "  --help        Show this help"
}

# Main program
case "$1" in
    --save)     save_theme ;;
    --apply)    apply_theme ;;
    --show)     show_theme ;;
    --save-as)  save_named "$2" ;;
    --load)     apply_named "$2" ;;
    --list)     list_themes ;;
    --help|-h)  show_help ;;
    *)          show_help; exit 1 ;;
esac

exit 0