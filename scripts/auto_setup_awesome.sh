#!/bin/bash

# auto_setup_awesome.sh - Single entry point for AwesomeWM setup
# Supports Arch Linux and Debian-based systems

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
AWESOME_CONFIG="$HOME/.config/awesome"

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

# Step 3: Copy configuration files to ~/.config/awesome
sync_config() {
    log "Syncing configuration files..."
    
    # Create directories
    mkdir -p "$AWESOME_CONFIG/modules"
    mkdir -p "$AWESOME_CONFIG/data/notifications/icons"
    mkdir -p "$AWESOME_CONFIG/themes/settings"
    mkdir -p "$AWESOME_CONFIG/logs"
    
    # Copy main config
    if [ -f "$PROJECT_DIR/rc.lua" ]; then
        cp "$PROJECT_DIR/rc.lua" "$AWESOME_CONFIG/rc.lua"
        log "Copied rc.lua"
    fi
    
    # Copy modules (including notification_center)
    if [ -d "$PROJECT_DIR/modules" ]; then
        cp -r "$PROJECT_DIR/modules/"* "$AWESOME_CONFIG/modules/" 2>/dev/null || true
        log "Copied modules"
    fi
    
    # Copy themes
    if [ -d "$PROJECT_DIR/themes" ]; then
        cp -r "$PROJECT_DIR/themes/"* "$AWESOME_CONFIG/themes/" 2>/dev/null || true
        log "Copied themes"
    fi
    
    # Copy wallpapers
    if [ -d "$PROJECT_DIR/wallpapers" ]; then
        mkdir -p "$AWESOME_CONFIG/wallpapers"
        cp -r "$PROJECT_DIR/wallpapers/"* "$AWESOME_CONFIG/wallpapers/" 2>/dev/null || true
        log "Copied wallpapers"
    fi
    
    # Copy scripts
    mkdir -p "$AWESOME_CONFIG/scripts"
    cp "$SCRIPT_DIR/"*.sh "$AWESOME_CONFIG/scripts/" 2>/dev/null || true
    chmod +x "$AWESOME_CONFIG/scripts/"*.sh 2>/dev/null || true
    log "Copied scripts"
    
    # Copy other config files
    [ -f "$PROJECT_DIR/set_wallpaper.sh" ] && cp "$PROJECT_DIR/set_wallpaper.sh" "$AWESOME_CONFIG/"
    
    success "Configuration synced to $AWESOME_CONFIG"
}

# Step 4: Install Nerd Fonts (optional)
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

# Step 5: Configure HiDPI (optional) - DISABLED BY DEFAULT
setup_hidpi() {
    echo ""
    warn "HiDPI scaling changes DPI for ALL applications."
    warn "Only enable this if you have a 4K/HiDPI display AND want 2x scaling."
    echo ""
    read -p "Configure HiDPI scaling? (y/n) [default: n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "DPI values: 96 (1x, standard), 144 (1.5x), 192 (2x)"
        read -p "Enter DPI [default: 96]: " DPI
        DPI=${DPI:-96}
        
        if [ "$DPI" -gt 96 ]; then
            read -p "Make persistent (modifies .xprofile)? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                "$SCRIPT_DIR/set_hidpi.sh" --persist "$DPI"
            else
                "$SCRIPT_DIR/set_hidpi.sh" --set "$DPI"
            fi
            success "HiDPI configured to $DPI"
        else
            log "Standard DPI (96) - no changes needed"
        fi
    else
        log "Skipped HiDPI configuration (recommended for most displays)"
    fi
}

# Step 6: Save current theme (optional)
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
    sync_config
    install_fonts
    setup_hidpi
    setup_theme
    
    echo ""
    success "Setup complete! Log out and back in, or restart Awesome (Super+Ctrl+r)"
}

main
