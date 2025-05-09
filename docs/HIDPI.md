# HiDPI Configuration for AwesomeWM

This guide explains how to use the HiDPI scaling features in this AwesomeWM configuration.

## Overview

The HiDPI support module provides several methods to adjust scaling for high-resolution displays:

1. **Automatic detection and scaling**
2. **Manual DPI adjustment through keybindings**
3. **A GUI control panel for fine adjustments**
4. **Command-line script for direct DPI setting**

## Using the GUI Control Panel

Press **Mod4+Ctrl+d** to open the DPI control panel. This panel allows you to:

- Select from predefined DPI presets
- Enter a custom DPI value
- Apply changes and restart AwesomeWM to ensure proper scaling

## Keybindings

The following keybindings are available for quick DPI adjustments:

- **Mod4+Ctrl+1**: Set to standard DPI (96)
- **Mod4+Ctrl+2**: Set to medium DPI (144)
- **Mod4+Ctrl+3**: Set to large DPI (192)
- **Mod4+Ctrl+4**: Set to extra large DPI (240)
- **Mod4+Ctrl+d**: Open DPI control panel

## Command-line Configuration

You can also use the included script to set DPI values from the command line:

```bash
~/.config/awesome/scripts/set_hidpi.sh [DPI_VALUE]
```

If no DPI value is provided, it defaults to 192 (2x scaling).

Examples:
```bash
# Set to standard DPI (1x scaling)
~/.config/awesome/scripts/set_hidpi.sh 96

# Set to 2x scaling (default)
~/.config/awesome/scripts/set_hidpi.sh 192

# Set to 1.5x scaling
~/.config/awesome/scripts/set_hidpi.sh 144
```

## Troubleshooting

### Applications Not Scaling Properly

Some applications may not respect X11 DPI settings. In these cases, you can:

1. Set environment variables in your `~/.profile` or `~/.xprofile`:

```bash
# For GTK applications
export GDK_SCALE=2
export GDK_DPI_SCALE=0.5

# For Qt applications
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_SCALE_FACTOR=2
```

2. For Firefox specifically, you can adjust the scaling in `about:config`:
   - Set `layout.css.devPixelsPerPx` to a higher value (e.g., 2.0 for 2x scaling)

### Scaling Issues with Specific Applications

Some applications may have their own scaling settings:

- **VSCode**: Use Ctrl+= to increase UI scale or set `window.zoomLevel` in settings
- **Electron apps**: Launch with `--force-device-scale-factor=2`

## Logs

The HiDPI module logs all changes to `~/.config/awesome/hidpi_scaling.log`, which can be helpful for troubleshooting.

## Technical Details

The scaling works by:

1. Setting the X server's DPI via `xrdb -merge`
2. Using this DPI value in AwesomeWM's `beautiful.xresources`
3. Setting environment variables for GTK and Qt applications
4. Applying the DPI consistently using the `hidpi.scale()` function 