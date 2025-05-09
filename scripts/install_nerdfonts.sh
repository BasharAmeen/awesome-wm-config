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

# Make sure the user running this script is not root
if [[ $EUID -eq 0 ]]; then
    error "This script should NOT be run as root. Please run as a normal user."
    exit 1
fi

# Create local font directory if it doesn't exist
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

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

# Download and install fonts
for font in "${FONTS[@]}"; do
    log "Downloading and installing $font Nerd Font..."
    
    # Create a temporary directory for downloading
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || exit 1
    
    # Download the font
    wget -q "$NERD_FONTS_URL/$NERD_FONTS_VERSION/$font.zip" -O "$font.zip"
    
    if [ $? -ne 0 ]; then
        error "Failed to download $font. Skipping..."
        continue
    fi
    
    # Extract the font to the fonts directory
    unzip -q "$font.zip" -d "$FONT_DIR/$font"
    
    if [ $? -eq 0 ]; then
        success "$font Nerd Font installed successfully."
    else
        error "Failed to extract $font."
    fi
    
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