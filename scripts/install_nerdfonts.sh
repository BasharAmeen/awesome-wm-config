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

warn() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# Make sure the user running this script is not root
if [[ $EUID -eq 0 ]]; then
    error "This script should NOT be run as root. Please run as a normal user."
    exit 1
fi

# Check for required commands
check_dependencies() {
    local missing_deps=()
    
    for cmd in wget unzip fc-cache; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        warn "Missing dependencies: ${missing_deps[*]}"
        log "Installing missing dependencies..."
        
        # Detect the distribution
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            
            if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
                # Arch Linux
                if ! sudo pacman -S --needed --noconfirm wget unzip fontconfig; then
                    error "Failed to install dependencies. Please install them manually: wget, unzip, fontconfig"
                    exit 1
                fi
            elif [[ "$ID" == "debian" || "$ID" == "ubuntu" || "$ID_LIKE" == *"debian"* ]]; then
                # Debian or Ubuntu based
                if ! sudo apt update && sudo apt install -y wget unzip fontconfig; then
                    error "Failed to install dependencies. Please install them manually: wget, unzip, fontconfig"
                    exit 1
                fi
            else
                error "Unsupported distribution: $ID. Please install the following packages manually: wget, unzip, fontconfig"
                exit 1
            fi
        else
            error "Cannot detect your distribution. Please install the following packages manually: wget, unzip, fontconfig"
            exit 1
        fi
    fi
}

# Check and install dependencies
check_dependencies

# Create local font directory if it doesn't exist
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
log "Font directory: $FONT_DIR"

# Nerd Fonts version
NERD_FONTS_VERSION="v3.1.1"
NERD_FONTS_URL="https://github.com/ryanoasis/nerd-fonts/releases/download"

# List of fonts to install
FONTS=(
    "JetBrainsMono"
    "FiraCode"
    "Hack"
    "SourceCodePro"
)

log "Installing Nerd Fonts for enhanced icons..."
log "Using Nerd Fonts version: $NERD_FONTS_VERSION"

# Download and install fonts
for font in "${FONTS[@]}"; do
    log "Downloading and installing $font Nerd Font..."
    
    # Create a temporary directory for downloading
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || {
        error "Failed to create or access temporary directory for $font"
        continue
    }
    
    # Download the font
    log "Downloading $font from $NERD_FONTS_URL/$NERD_FONTS_VERSION/$font.zip"
    if ! wget -q --show-progress "$NERD_FONTS_URL/$NERD_FONTS_VERSION/$font.zip" -O "$font.zip"; then
        error "Failed to download $font. Skipping..."
        cd - > /dev/null
        rm -rf "$TEMP_DIR"
        continue
    fi
    
    # Create font directory if it doesn't exist
    mkdir -p "$FONT_DIR/$font"
    
    # Extract the font to the fonts directory
    log "Extracting $font to $FONT_DIR/$font"
    if ! unzip -q "$font.zip" -d "$FONT_DIR/$font"; then
        error "Failed to extract $font."
        cd - > /dev/null
        rm -rf "$TEMP_DIR"
        continue
    fi
    
    success "$font Nerd Font installed successfully."
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
done

# Update font cache
log "Updating font cache..."
fc-cache -f

success "Nerd Fonts installation complete!"
log "To use these fonts in your terminal, configure your terminal preferences."
log "For Awesome WM, you may need to edit rc.lua to use these fonts."

# Suggest font configuration for the volume icon
cat << EOF

To use Nerd Fonts for your volume icon, edit rc.lua and change the font line to:

local volume_icon = wibox.widget {
    font = "JetBrainsMono Nerd Font 20",  -- Or any other Nerd Font you installed
    align = "center",
    valign = "center",
    widget = wibox.widget.textbox,
}

Then restart Awesome WM with Super+Ctrl+r.
EOF 