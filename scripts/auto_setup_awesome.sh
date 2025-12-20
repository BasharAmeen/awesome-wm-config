#!/bin/bash

# auto_setup_awesome.sh - Single entry point for AwesomeWM setup
# Supports Arch Linux and Debian-based systems

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Colors
log()     { echo -e "\033[1;34m[INFO]\033[0m $1"; }
success() { echo -e "\033[1;32m[OK]\033[0m $1"; }
error()   { echo -e "\033[1;31m[ERROR]\033[0m $1"; }
warn()    { echo -e "\033[1;33m[WARN]\033[0m $1"; }

# Check sudo
if ! sudo -v; then
    error "This script requires sudo access."
    exit 1
fi

# Detect distro
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "arch" ] || [[ "$ID_LIKE" == *"arch"* ]]; then
            echo "arch"
        elif [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ] || [[ "$ID_LIKE" == *"debian"* ]]; then
            echo "debian"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)
if [ "$DISTRO" = "unknown" ]; then
    error "Unsupported Linux distribution"
    exit 1
fi
log "Detected: $DISTRO"

# Step 1: Install Awesome WM
install_awesome() {
    if command -v awesome &>/dev/null; then
        success "Awesome WM already installed"
        return
    fi
    
    log "Installing Awesome WM..."
    if [ "$DISTRO" = "arch" ]; then
        sudo pacman -S --needed --noconfirm awesome
    else
        sudo apt update && sudo apt install -y awesome
    fi
    success "Awesome WM installed"
}

# Step 2: Install dependencies
install_deps() {
    log "Installing dependencies..."
    sudo "$SCRIPT_DIR/install_deps.sh" --os "$DISTRO"
    success "Dependencies installed"
}

# Step 3: Install Nerd Fonts (optional)
install_fonts() {
    read -p "Install Nerd Fonts for icons? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        "$SCRIPT_DIR/install_nerdfonts.sh"
        success "Nerd Fonts installed"
    else
        warn "Skipped Nerd Fonts"
    fi
}

# Step 4: Configure HiDPI (optional)
setup_hidpi() {
    read -p "Configure HiDPI scaling? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter DPI (96=1x, 144=1.5x, 192=2x): " DPI
        DPI=${DPI:-192}
        
        read -p "Make persistent (create xprofile)? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            "$SCRIPT_DIR/set_hidpi.sh" --persist "$DPI"
        else
            "$SCRIPT_DIR/set_hidpi.sh" --set "$DPI"
        fi
        success "HiDPI configured"
    else
        warn "Skipped HiDPI"
    fi
}

# Step 5: Save current theme (optional)
setup_theme() {
    read -p "Save current theme settings? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Theme name (leave empty for default): " THEME_NAME
        if [ -n "$THEME_NAME" ]; then
            "$SCRIPT_DIR/set_theme.sh" --save-as "$THEME_NAME"
        else
            "$SCRIPT_DIR/set_theme.sh" --save
        fi
        success "Theme saved"
    else
        warn "Skipped theme"
    fi
}

# Main
main() {
    echo ""
    echo "========================================"
    echo "  AwesomeWM Setup - $DISTRO"
    echo "========================================"
    echo ""
    
    install_awesome
    install_deps
    install_fonts
    setup_hidpi
    setup_theme
    
    echo ""
    success "Setup complete! Log out and back in, or restart Awesome (Super+Ctrl+r)"
}

main
