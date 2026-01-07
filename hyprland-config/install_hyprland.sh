#!/bin/bash
set -e

# Detect Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo "Error: This script is designed for Arch Linux."
    exit 1
fi

echo "Installing Hyprland and dependencies..."

# Install packages
# core: hyprland
# system: xdg-desktop-portal-hyprland qt5-wayland qt6-wayland polkit-kde-agent
# status bar: waybar
# notifications: swaync
# launcher: rofi-wayland
# wallpaper: swww
# lock: hyprlock
# idle: hypridle
# screenshot: grim slurp flameshot
# file manager: thunar
PACKAGES="hyprland waybar swaync rofi-wayland swww hyprlock hypridle \
xdg-desktop-portal-hyprland qt5-wayland qt6-wayland polkit-kde-agent \
alacritty firefox thunar ttf-font-awesome ttf-nerd-fonts-symbols-mono flameshot \
grim slurp"

echo "Installing: $PACKAGES"
if command -v yay &> /dev/null; then
    yay -S --needed --noconfirm $PACKAGES
else
    sudo pacman -S --needed --noconfirm $PACKAGES
fi

# Create config directories
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar
mkdir -p ~/.config/swaync

# Backup existing configs
TIMESTAMP=$(date +%Y%m%d%H%M%S)
if [ -f ~/.config/hypr/hyprland.conf ]; then
    echo "Backing up existing hyprland.conf..."
    mv ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.bak.$TIMESTAMP
fi

if [ -d ~/.config/waybar ]; then
    echo "Backing up existing waybar config..."
    mv ~/.config/waybar ~/.config/waybar.bak.$TIMESTAMP
    mkdir -p ~/.config/waybar
fi

# Copy Configs
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Deploying configs..."
cp "$SCRIPT_DIR/hyprland.conf" ~/.config/hypr/hyprland.conf
cp "$SCRIPT_DIR/waybar/config.jsonc" ~/.config/waybar/config.jsonc
cp "$SCRIPT_DIR/waybar/style.css" ~/.config/waybar/style.css

# Set execution permissions
chmod +x ~/.config/hypr/hyprland.conf

echo "Installation Complete!"
echo "Please log out and select 'Hyprland' from your login session."
