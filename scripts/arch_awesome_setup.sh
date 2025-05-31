#!/bin/bash

# arch_awesome_setup.sh - One-stop setup script for AwesomeWM on Arch Linux
# This script handles all dependencies and configurations for a complete setup

# Log file
LOG_FILE="$HOME/.config/awesome/awesome_setup.log"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

# Timestamp for log
echo "$(date): Starting Arch Linux AwesomeWM setup" > "$LOG_FILE"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Log functions with both console and file output
log() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
    echo "$(date): [INFO] $1" >> "$LOG_FILE"
}

error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
    echo "$(date): [ERROR] $1" >> "$LOG_FILE"
}

success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
    echo "$(date): [SUCCESS] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
    echo "$(date): [WARNING] $1" >> "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    error "An error occurred in section: $1"
    error "Command exited with status: $2"
    echo "$(date): [ERROR_DETAILS] Error in section '$1' with exit code $2" >> "$LOG_FILE"
}

# Check if running on Arch Linux
check_arch_linux() {
    log "Checking if running on Arch Linux..."
    
    if [ -f "/etc/arch-release" ]; then
        success "Arch Linux detected."
        return 0
    elif grep -q "ID=arch" /etc/os-release || grep -q "ID_LIKE=.*arch" /etc/os-release; then
        success "Arch-based distribution detected."
        return 0
    else
        error "This script is specifically for Arch Linux."
        error "If you're running a different distribution, please use the appropriate setup script."
        return 1
    fi
}

# Check if running as root
check_root() {
    log "Checking if running as root..."
    
    if [[ $EUID -eq 0 ]]; then
        success "Running as root."
        return 0
    else
        error "This script must be run as root."
        error "Please run with: sudo $0"
        return 1
    fi
}

# Install base dependencies
install_dependencies() {
    log "Installing dependencies..."
    
    if [ -f "$SCRIPT_DIR/install_deps.sh" ]; then
        log "Running install_deps.sh..."
        bash "$SCRIPT_DIR/install_deps.sh" --os arch
        if [ $? -ne 0 ]; then
            handle_error "install_dependencies" $?
            error "Failed to install dependencies."
            return 1
        fi
    else
        error "install_deps.sh not found in $SCRIPT_DIR"
        
        # Fallback: Install core dependencies directly
        log "Falling back to direct package installation..."
        
        pacman -Sy --noconfirm awesome picom alacritty ttf-font-awesome \
               noto-fonts noto-fonts-emoji light pulseaudio-utils copyq \
               network-manager-applet gmrun libinput gnome-keyring \
               curl wget git unzip xorg-xset flameshot
        
        if [ $? -ne 0 ]; then
            handle_error "install_dependencies_fallback" $?
            error "Failed to install core dependencies."
            return 1
        fi
    fi
    
    success "Dependencies installed successfully."
    return 0
}

# Install Nerd Fonts
install_nerd_fonts() {
    log "Setting up Nerd Fonts..."
    
    if [ -f "$SCRIPT_DIR/install_nerdfonts.sh" ]; then
        log "Running install_nerdfonts.sh..."
        bash "$SCRIPT_DIR/install_nerdfonts.sh"
        if [ $? -ne 0 ]; then
            handle_error "install_nerd_fonts" $?
            warn "Failed to install Nerd Fonts, but continuing with setup."
        fi
    else
        warn "install_nerdfonts.sh not found in $SCRIPT_DIR"
        log "Downloading Hack Nerd Font as fallback..."
        
        FONT_DIR="$HOME/.local/share/fonts"
        mkdir -p "$FONT_DIR"
        
        wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip" -O /tmp/Hack.zip
        if [ $? -ne 0 ]; then
            handle_error "download_nerd_fonts" $?
            warn "Failed to download Nerd Fonts, but continuing with setup."
        else
            unzip -o /tmp/Hack.zip -d "$FONT_DIR"
            fc-cache -f
            success "Hack Nerd Font installed."
        fi
    fi
    
    return 0
}

# Configure HiDPI settings
setup_hidpi() {
    log "Setting up HiDPI configuration..."
    
    if [ -f "$SCRIPT_DIR/create_xprofile.sh" ]; then
        log "Running create_xprofile.sh..."
        bash "$SCRIPT_DIR/create_xprofile.sh"
        if [ $? -ne 0 ]; then
            handle_error "setup_hidpi_xprofile" $?
            warn "Failed to create xprofile for HiDPI."
        fi
    else
        warn "create_xprofile.sh not found in $SCRIPT_DIR"
    fi
    
    # Ask for DPI value
    read -p "Would you like to enable HiDPI scaling? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter DPI value (default is 192 for 2x scaling, 144 for 1.5x): " DPI_VALUE
        DPI_VALUE=${DPI_VALUE:-192}
        
        if [ -f "$SCRIPT_DIR/set_hidpi.sh" ]; then
            log "Running set_hidpi.sh with DPI $DPI_VALUE..."
            bash "$SCRIPT_DIR/set_hidpi.sh" "$DPI_VALUE"
            if [ $? -ne 0 ]; then
                handle_error "setup_hidpi_scaling" $?
                warn "Failed to set HiDPI scaling."
            fi
        else
            warn "set_hidpi.sh not found in $SCRIPT_DIR"
            
            # Basic HiDPI setup
            echo "Xft.dpi: $DPI_VALUE" | xrdb -merge
            log "Set Xft.dpi to $DPI_VALUE"
        fi
    fi
    
    return 0
}

# Set up theme
setup_theme() {
    log "Setting up theme..."
    
    # Ask user if they want to select a theme
    read -p "Would you like to set up a theme for AwesomeWM? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "$SCRIPT_DIR/theme_manager.sh" ]; then
            log "Running theme_manager.sh..."
            bash "$SCRIPT_DIR/theme_manager.sh"
            if [ $? -ne 0 ]; then
                handle_error "setup_theme_manager" $?
                warn "Failed to run theme manager."
            fi
        elif [ -f "$SCRIPT_DIR/set_theme.sh" ]; then
            log "Running set_theme.sh..."
            bash "$SCRIPT_DIR/set_theme.sh"
            if [ $? -ne 0 ]; then
                handle_error "setup_theme" $?
                warn "Failed to set theme."
            fi
        else
            warn "No theme scripts found in $SCRIPT_DIR"
        fi
    else
        log "Skipping theme setup."
    fi
    
    return 0
}

# Run tests to make sure everything is working
test_setup() {
    log "Testing the setup..."
    
    if [ -f "$SCRIPT_DIR/test_awesome_setup.sh" ]; then
        log "Running test_awesome_setup.sh..."
        bash "$SCRIPT_DIR/test_awesome_setup.sh"
        if [ $? -ne 0 ]; then
            handle_error "test_setup" $?
            warn "Tests failed, but continuing with setup."
        fi
    else
        warn "test_awesome_setup.sh not found in $SCRIPT_DIR"
        
        # Basic test to check if awesome is installed
        if command -v awesome &> /dev/null; then
            success "Awesome WM is installed."
            awesome --version | head -n 1
        else
            error "Awesome WM is not installed or not in PATH."
            return 1
        fi
    fi
    
    return 0
}

# Main function to orchestrate the setup
main() {
    log "Starting Arch Linux AwesomeWM setup..."
    
    # Check if running on Arch Linux
    check_arch_linux || exit 1
    
    # Check if running as root
    check_root || exit 1
    
    # Install dependencies
    install_dependencies || exit 1
    
    # Install Nerd Fonts (non-critical, continue on failure)
    install_nerd_fonts
    
    # Set up HiDPI settings (non-critical, continue on failure)
    setup_hidpi
    
    # Set up theme (non-critical, continue on failure)
    setup_theme
    
    # Test setup (non-critical, continue on failure)
    test_setup
    
    success "Arch Linux AwesomeWM setup completed successfully!"
    log "You may need to log out and log back in for all changes to take effect."
    log "If you experience any issues, check the log file at $LOG_FILE"
}

# Run the main function
main

exit 0 