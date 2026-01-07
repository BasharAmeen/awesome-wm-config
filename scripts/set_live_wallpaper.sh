#!/bin/bash

# Configuration
WALLPAPER_DIR="$HOME/.config/awesome/wallpapers"
VIDEO_WALLPAPER="$WALLPAPER_DIR/awesome_tech_drone.mp4"
STATIC_WALLPAPER="$WALLPAPER_DIR/awesome_tech_drone.png"

# Kill existing wallpaper processes
pkill -f "mpv.*live_wallpaper"

# Check if video wallpaper exists
if [ -f "$VIDEO_WALLPAPER" ]; then
    # Run mpv as a window with special instance name for AwesomeWM to match
    # --x11-name sets the WM_CLASS instance to "live_wallpaper" for rule matching
    # --loop-file=inf loops forever
    # --no-audio mutes sound
    # --no-osc removes on-screen controller
    # --no-osd-bar removes on-screen display
    # --no-border removes window border
    # --no-input-default-bindings disables keyboard controls
    # Redirect stdin/out/err to detach from terminal
    mpv --x11-name=live_wallpaper --loop-file=inf --no-audio --no-osc --no-osd-bar --no-border --no-input-default-bindings --quiet "$VIDEO_WALLPAPER" >/dev/null 2>&1 < /dev/null &
    disown
else
    # Fallback to static wallpaper using nitrogen or feh if installed, or just notify user to create video
    # Since AwesomeWM handles static wallpapers internally via gears.wallpaper, we might not need to do anything here
    # IF this script is ONLY for the live wallpaper part.
    # However, let's use feh or just exit if not found so AwesomeWM default kicks in.
    if command -v feh &> /dev/null; then
        feh --bg-fill "$STATIC_WALLPAPER"
    fi
     echo "Video wallpaper not found at $VIDEO_WALLPAPER"
fi
