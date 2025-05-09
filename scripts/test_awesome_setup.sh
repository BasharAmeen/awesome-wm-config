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

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Detect the Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_LIKE=$ID_LIKE
    log "Detected distribution: $DISTRO (ID_LIKE: $DISTRO_LIKE)"
else
    error "Could not detect the Linux distribution."
    exit 1
fi

# Test distribution detection
log "Testing distribution detection logic..."
if [ "$DISTRO" = "arch" ]; then
    success "Detected as Arch Linux"
elif [ "$DISTRO" = "debian" ]; then
    success "Detected as Debian"
elif [ "$DISTRO" = "ubuntu" ]; then
    success "Detected as Ubuntu"
elif [[ "$DISTRO_LIKE" == *"debian"* ]]; then
    success "Detected as Debian-based distribution: $DISTRO"
elif [[ "$DISTRO_LIKE" == *"arch"* ]]; then
    success "Detected as Arch-based distribution: $DISTRO"
else
    warn "Unknown distribution: $DISTRO with ID_LIKE: $DISTRO_LIKE"
fi

# Check for dependencies needed by all scripts
log "Checking for essential dependencies..."
ESSENTIAL_DEPS=("wget" "git" "unzip")
MISSING_DEPS=()

for dep in "${ESSENTIAL_DEPS[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    warn "Missing essential dependencies: ${MISSING_DEPS[*]}"
    log "These will be installed by the scripts when needed."
else
    success "All essential dependencies are already installed."
fi

# Check for awesome
if command -v awesome &> /dev/null; then
    success "Awesome WM is already installed."
    awesome --version | head -n 1
else
    warn "Awesome WM is not installed. It will be installed by the setup script."
fi

# Ask if user would like to proceed with full setup
read -p "Would you like to proceed with the full Awesome WM setup? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Running the main setup script..."
    bash "$SCRIPT_DIR/auto_setup_awesome.sh"
else
    log "Skipping the full setup."
    log "You can run the setup later with: bash $SCRIPT_DIR/auto_setup_awesome.sh"
fi 