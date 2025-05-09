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

# Function to detect OS
detect_os() {
    if [ -f "/etc/arch-release" ]; then
        echo "arch"
    elif [ -f "/etc/debian_version" ]; then
        echo "debian"
    else
        # Check OS-release for more information
        if grep -q "ID=arch" /etc/os-release; then 
            echo "arch"
            return
        fi
        if grep -q "ID=debian\|ID=ubuntu\|ID=linuxmint\|ID=pop\|ID=elementary\|ID=zorin\|ID=parrot\|ID=kali\|ID=deepin" /etc/os-release; then 
            echo "debian"
            return
        fi
        if grep -q "ID_LIKE=.*debian" /etc/os-release; then 
            echo "debian"
            return
        fi
        if grep -q "ID_LIKE=.*arch" /etc/os-release; then 
            echo "arch"
            return
        fi
        echo "unknown"
    fi
}

# Show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Install dependencies for enhanced Awesome WM setup."
    echo
    echo "Options:"
    echo "  -o, --os OSTYPE    Specify the OS type (arch or debian)"
    echo "  -h, --help         Show this help message"
    echo
    echo "If no OS is specified, the script will attempt to auto-detect."
}

# Parse command-line arguments
OS_TYPE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--os)
            OS_TYPE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Auto-detect OS if not specified
if [ -z "$OS_TYPE" ]; then
    OS_TYPE=$(detect_os)
    if [ "$OS_TYPE" = "unknown" ]; then
        error "Could not detect your OS. Please specify with --os option."
        exit 1
    fi
    log "Detected OS: $OS_TYPE"
else
    # Validate OS input
    if [ "$OS_TYPE" != "arch" ] && [ "$OS_TYPE" != "debian" ]; then
        error "Invalid OS type. Supported types: arch, debian"
        exit 1
    fi
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root. Please use sudo."
    exit 1
fi

log "Checking and installing dependencies for enhanced Awesome WM setup on $OS_TYPE..."

# Define packages for each OS
DEBIAN_PACKAGES=(
    "picom"                # Compositor for transparency effects (used for visual effects)
    "flameshot"            # Screenshot tool (used for screenshots)
    "alacritty"            # Terminal (explicitly used as terminal)
    # "rofi"                 # Modern application launcher (used for app launching)
    "fonts-font-awesome"   # Icon font for UI elements (used for system widgets)
    "fonts-noto"           # Comprehensive font with good Unicode coverage
    "fonts-noto-color-emoji" # Emoji font
    "light"                # Backlight control (used for brightness adjustment)
    "pulseaudio-utils"     # Audio controls (used for volume control)
    # "firefox"              # Browser (explicitly defined as browser)
    "copyq"                # Clipboard manager (spawned in autostart)
    "network-manager-gnome" # Network management (nm-applet spawned in autostart)
    "gmrun"                # Run prompt (launched with modkey+r)
    "libinput-tools"       # For touchpad settings
    "gnome-keyring"        # Used in autostart
    "curl"                 # Required for downloading resources
    "wget"                 # Alternative for downloads
    "git"                  # Used for cloning repositories
    "unzip"                # For extracting archives
    "x11-xserver-utils"    # X utilities
)

# Ubuntu might need different package names for some packages
UBUNTU_FALLBACK_PACKAGES=(
    "light|brightnessctl"  # Try light first, fall back to brightnessctl
)

ARCH_PACKAGES=(
    "picom"                # Compositor for transparency effects (used for visual effects)
    "flameshot"            # Screenshot tool (used for screenshots)
    "alacritty"            # Terminal (explicitly used as terminal)
    # "rofi"                 # Modern application launcher (used for app launching)
    "ttf-font-awesome"     # Icon font for UI elements (used for system widgets)
    "noto-fonts"           # Comprehensive font with good Unicode coverage
    "noto-fonts-emoji"     # Emoji font
    "light"                # Backlight control (used for brightness adjustment)
    "pulseaudio-utils"     # Audio controls (used for volume control)
    # "firefox"              # Browser (explicitly defined as browser)
    "copyq"                # Clipboard manager (spawned in autostart)
    "network-manager-applet" # Network management (nm-applet spawned in autostart)
    "gmrun"                # Run prompt (launched with modkey+r)
    "libinput"             # For touchpad settings
    "gnome-keyring"        # Used in autostart
    "curl"                 # Required for downloading resources
    "wget"                 # Alternative for downloads
    "git"                  # Used for cloning repositories
    "unzip"                # For extracting archives
    "xorg-xset"            # X utilities
)

# Update package lists based on distro
if [ "$OS_TYPE" = "debian" ]; then
    log "Updating package lists..."
    apt update
    PACKAGES=("${DEBIAN_PACKAGES[@]}")
    INSTALL_CMD="apt install -y"
    
    # Check for Ubuntu and its derivatives
    if grep -q "ID=ubuntu\|ID_LIKE=.*ubuntu" /etc/os-release; then
        log "Ubuntu-based system detected. Adding fallback packages..."
        # Also add Ubuntu-specific fallback packages
        PACKAGES+=("${UBUNTU_FALLBACK_PACKAGES[@]}")
    fi
    
elif [ "$OS_TYPE" = "arch" ]; then
    log "Updating package lists..."
    pacman -Sy
    PACKAGES=("${ARCH_PACKAGES[@]}")
    INSTALL_CMD="pacman -S --noconfirm"
fi

# Check if packages are installed and install if missing
for pkg in "${PACKAGES[@]}"; do
    # Skip commented out packages
    if [[ $pkg == \#* ]]; then
        continue
    fi
    
    # For Ubuntu fallback packages (format: pkg1|pkg2)
    if [[ $pkg == *"|"* ]] && [ "$OS_TYPE" = "debian" ]; then
        primary_pkg=$(echo $pkg | cut -d'|' -f1)
        fallback_pkg=$(echo $pkg | cut -d'|' -f2)
        
        log "Checking for $primary_pkg or $fallback_pkg..."
        if dpkg -s "$primary_pkg" >/dev/null 2>&1; then
            log "$primary_pkg is already installed."
        elif dpkg -s "$fallback_pkg" >/dev/null 2>&1; then
            log "$fallback_pkg is already installed."
        else
            log "Trying to install $primary_pkg..."
            if apt install -y "$primary_pkg" >/dev/null 2>&1; then
                success "$primary_pkg installed successfully."
            else
                log "Failed to install $primary_pkg, trying $fallback_pkg..."
                if apt install -y "$fallback_pkg" >/dev/null 2>&1; then
                    success "$fallback_pkg installed successfully."
                else
                    error "Failed to install both $primary_pkg and $fallback_pkg."
                fi
            fi
        fi
        continue
    fi
    
    if [ "$OS_TYPE" = "debian" ]; then
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            log "$pkg is already installed."
        else
            log "Installing $pkg..."
            apt install -y "$pkg"
            if [ $? -eq 0 ]; then
                success "$pkg installed successfully."
            else
                error "Failed to install $pkg."
                warn "You may need to install this package manually."
            fi
        fi
    elif [ "$OS_TYPE" = "arch" ]; then
        if pacman -Qi "$pkg" >/dev/null 2>&1; then
            log "$pkg is already installed."
        else
            log "Installing $pkg..."
            pacman -S --noconfirm "$pkg"
            if [ $? -eq 0 ]; then
                success "$pkg installed successfully."
            else
                error "Failed to install $pkg."
            fi
        fi
    fi
done

# Clone or update lain (if not already present)
log "Checking for lain library..."
if [ -d "$HOME/.config/awesome/lain" ]; then
    log "Updating lain library..."
    cd "$HOME/.config/awesome/lain" && git pull
else
    log "Installing lain library..."
    # Ensure git is installed
    if ! command -v git &> /dev/null; then
        log "Git not found. Installing git..."
        if [ "$OS_TYPE" = "debian" ]; then
            apt install -y git
        elif [ "$OS_TYPE" = "arch" ]; then
            pacman -S --noconfirm git
        fi
    fi
    
    # Create awesome config directory if it doesn't exist
    if [ ! -d "$HOME/.config/awesome" ]; then
        log "Creating awesome config directory..."
        mkdir -p "$HOME/.config/awesome"
    fi
    
    git clone https://github.com/lcpz/lain.git "$HOME/.config/awesome/lain"
fi

# Create picom configuration directory if it doesn't exist
if [ ! -d "$HOME/.config/picom" ]; then
    log "Creating picom configuration directory..."
    mkdir -p "$HOME/.config/picom"
fi

# Set correct permissions for the user
ACTUAL_USER=$(logname 2>/dev/null || who am i | awk '{print $1}')
if [ -z "$ACTUAL_USER" ]; then
    ACTUAL_USER=$(who | grep -v root | head -n 1 | awk '{print $1}')
    if [ -z "$ACTUAL_USER" ]; then
        warn "Could not determine the actual user. Using SUDO_USER environment variable."
        ACTUAL_USER=$SUDO_USER
    fi
fi

if [ -n "$ACTUAL_USER" ]; then
    log "Setting correct permissions for user $ACTUAL_USER..."
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$HOME/.config/awesome" 2>/dev/null || warn "Could not set permissions for awesome directory"
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$HOME/.config/picom" 2>/dev/null || warn "Could not set permissions for picom directory"
else
    error "Could not determine the actual user. Please set permissions manually."
fi

success "All dependencies installed and configured!"
log "Please restart Awesome WM with 'Super+Ctrl+r' to apply changes." 