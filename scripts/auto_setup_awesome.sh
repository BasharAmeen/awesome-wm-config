#! /bin/bash

# This is script is used to automatically setup the awesome wm environment.
# Currently supports debian-based systems + arch linux.

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if the user has sudo access
if ! sudo -v; then
    echo "Error: This script requires sudo access."
    exit 1
fi

# Detect the Linux distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Error: Could not detect the Linux distribution."
    exit 1
fi

# install awesome wm if not installed
if ! command -v awesome &> /dev/null; then
    echo "Installing Awesome WM..."
    if [ "$DISTRO" = "arch" ]; then
        sudo pacman -S --needed --noconfirm awesome
    elif [ "$DISTRO" = "debian" ]; then
        sudo apt install -y awesome
    else
        echo "Error: Unsupported Linux distribution."
        exit 1
    fi
fi

# Install dependencies
if [ "$DISTRO" = "arch" ]; then
    sudo "$SCRIPT_DIR/install_deps.sh" --os arch
elif [ "$DISTRO" = "debian" ]; then
    sudo "$SCRIPT_DIR/install_deps.sh" --os debian
else
    echo "Error: Unsupported Linux distribution."
    exit 1
fi

echo "Awesome WM setup completed successfully!"

