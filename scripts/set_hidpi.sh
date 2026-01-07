#!/bin/bash

# set_hidpi.sh - Script to set HiDPI scaling for displays
# Usage: ./set_hidpi.sh [OPTIONS] [DPI_VALUE]
#
# SAFETY: Default DPI is 96 (standard). Only use higher values if you have a HiDPI display.

LOG_FILE="$HOME/.config/awesome/logs/hidpi.log"
XPROFILE="$HOME/.xprofile"
HIDPI_MARKER="# HiDPI settings - Managed by set_hidpi.sh"

log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

# Set DPI for current session only (non-persistent)
set_dpi() {
    local dpi="${1:-96}"  # Default to 96 (standard DPI)
    
    if [ "$dpi" -gt 96 ]; then
        local scale=$((dpi / 96))
        log "Setting DPI to $dpi (${scale}x scaling) for current session"
        
        # Set X resource DPI
        echo "Xft.dpi: $dpi" | xrdb -merge
        
        # Environment variables for current session
        export GDK_SCALE=$scale
        export GDK_DPI_SCALE=$(awk -v scale="$scale" 'BEGIN {printf "%.2f", 1/scale}')
        export QT_AUTO_SCREEN_SCALE_FACTOR=1
        export QT_SCALE_FACTOR=$scale
    else
        log "Setting standard DPI (96) for current session"
        echo "Xft.dpi: 96" | xrdb -merge
        unset GDK_SCALE GDK_DPI_SCALE QT_SCALE_FACTOR
    fi
    
    # Restart Awesome to apply changes
    if command -v awesome-client &>/dev/null; then
        echo "awesome.restart()" | awesome-client 2>>"$LOG_FILE" || true
        log "Awesome restart requested"
    fi
    
    log "DPI set to $dpi for current session. Re-login for full effect."
}

# Remove HiDPI settings from xprofile
remove_hidpi_from_xprofile() {
    if [ -f "$XPROFILE" ]; then
        # Backup first
        cp "$XPROFILE" "${XPROFILE}.bak.$(date +%Y%m%d%H%M%S)"
        
        # Remove HiDPI block (between marker and next blank line or EOF)
        sed -i "/$HIDPI_MARKER/,/^$/d" "$XPROFILE"
        
        # Also remove any standalone HiDPI exports
        sed -i '/^export GDK_SCALE=/d' "$XPROFILE"
        sed -i '/^export GDK_DPI_SCALE=/d' "$XPROFILE"
        sed -i '/^export QT_SCALE_FACTOR=/d' "$XPROFILE"
        sed -i '/^export QT_AUTO_SCREEN_SCALE_FACTOR=/d' "$XPROFILE"
        sed -i '/^export ELECTRON_FORCE_DEVICE_SCALE_FACTOR=/d' "$XPROFILE"
        sed -i '/^export _JAVA_OPTIONS=.*uiScale/d' "$XPROFILE"
        sed -i '/Xft.dpi.*xrdb/d' "$XPROFILE"
        
        log "Removed HiDPI settings from $XPROFILE"
    fi
}

# Add HiDPI settings to xprofile (append, don't overwrite)
add_hidpi_to_xprofile() {
    local dpi="${1:-96}"
    local scale=$((dpi / 96))
    local dpi_scale="1"
    [ "$scale" -eq 2 ] && dpi_scale="0.5"
    [ "$scale" -eq 3 ] && dpi_scale="0.33"
    
    # First remove any existing HiDPI settings
    remove_hidpi_from_xprofile
    
    # Backup existing xprofile
    [ -f "$XPROFILE" ] && cp "$XPROFILE" "${XPROFILE}.bak.$(date +%Y%m%d%H%M%S)"
    
    # Append HiDPI settings
    cat >> "$XPROFILE" << EOF

$HIDPI_MARKER
# DPI: $dpi (${scale}x scaling)
echo "Xft.dpi: $dpi" | xrdb -merge
export GDK_SCALE=$scale
export GDK_DPI_SCALE=$dpi_scale
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_SCALE_FACTOR=$scale
export _JAVA_OPTIONS='-Dsun.java2d.uiScale=$scale'
export ELECTRON_FORCE_DEVICE_SCALE_FACTOR=$scale

EOF
    
    log "Added HiDPI settings (DPI $dpi) to $XPROFILE"
}

# Reset to standard DPI (96)
reset_dpi() {
    log "Resetting DPI to standard (96)..."
    
    # Remove from xprofile
    remove_hidpi_from_xprofile
    
    # Reset X resources
    echo "Xft.dpi: 96" | xrdb -merge
    
    # Create/update .Xresources
    if [ -f "$HOME/.Xresources" ]; then
        sed -i '/Xft.dpi/d' "$HOME/.Xresources"
    fi
    echo "Xft.dpi: 96" >> "$HOME/.Xresources"
    
    log "DPI reset to 96. Please log out and back in for full effect."
}

show_help() {
    echo "Usage: $0 [OPTION] [DPI]"
    echo ""
    echo "Options:"
    echo "  --set [DPI]       Set DPI for current session only (default: 96)"
    echo "  --persist [DPI]   Add HiDPI settings to .xprofile (appends, doesn't overwrite)"
    echo "  --reset           Remove all HiDPI settings and reset to standard DPI (96)"
    echo "  --help            Show this help"
    echo ""
    echo "DPI values: 96 (1x, standard), 144 (1.5x), 192 (2x), 288 (3x)"
    echo ""
    echo "IMPORTANT: Default DPI is 96 (standard). Only use higher values for HiDPI displays."
}

case "$1" in
    --set)      set_dpi "${2:-96}" ;;
    --persist)  
        warn "This will add HiDPI settings to your .xprofile"
        read -p "Continue with DPI ${2:-96}? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            add_hidpi_to_xprofile "${2:-96}"
        else
            echo "Cancelled."
        fi
        ;;
    --reset)    reset_dpi ;;
    --help|-h)  show_help ;;
    [0-9]*)     set_dpi "$1" ;;  # Backward compatible: just DPI value
    *)          show_help ;;
esac

exit 0