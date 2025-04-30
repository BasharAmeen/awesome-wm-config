#!/bin/bash

# Log function for better output
log() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root. Please use sudo."
    exit 1
fi

log "Checking and installing dependencies for enhanced Awesome WM setup..."

# Update package lists
log "Updating package lists..."
apt update

# List of required packages
PACKAGES=(
    "picom"               # Compositor for transparency effects
    "dmenu"               # Application launcher
    "flameshot"           # Screenshot tool
    "alacritty"           # Terminal
    "rofi"                # Modern application launcher (alternative to dmenu)
    "fonts-font-awesome"  # Icon font for UI elements
    "fonts-noto"          # Comprehensive font with good Unicode coverage
    "fonts-noto-color-emoji" # Emoji font
    "fonts-materialdesignicons-webfont" # Material Design Icons
    "lxappearance"        # Theme configuration
    "qt5ct"               # Qt5 theme configuration
    "nitrogen"            # Wallpaper manager
    "arandr"              # Screen layout editor
    "xbacklight"          # Backlight control
    "pulseaudio-utils"    # Audio controls
    "thunar"              # File manager
    "network-manager-gnome" # Network management
    "copyq"               # Clipboard manager
)

# Check if packages are installed and install if missing
for pkg in "${PACKAGES[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        log "$pkg is already installed."
    else
        log "Installing $pkg..."
        apt install -y "$pkg"
        if [ $? -eq 0 ]; then
            success "$pkg installed successfully."
        else
            error "Failed to install $pkg."
        fi
    fi
done

# Clone or update lain (if not already present)
if [ -d "$HOME/.config/awesome/lain" ]; then
    log "Updating lain library..."
    cd "$HOME/.config/awesome/lain" && git pull
else
    log "Installing lain library..."
    git clone https://github.com/lcpz/lain.git "$HOME/.config/awesome/lain"
fi

# Create picom configuration directory if it doesn't exist
if [ ! -d "$HOME/.config/picom" ]; then
    log "Creating picom configuration directory..."
    mkdir -p "$HOME/.config/picom"
fi

# Set correct permissions for the user
ACTUAL_USER=$(logname)
log "Setting correct permissions for user $ACTUAL_USER..."
chown -R "$ACTUAL_USER:$ACTUAL_USER" "$HOME/.config/awesome"
chown -R "$ACTUAL_USER:$ACTUAL_USER" "$HOME/.config/picom"

success "All dependencies installed and configured!"
log "Please restart Awesome WM with 'Super+Ctrl+r' to apply changes." 