# Theme Manager Scripts

This directory contains scripts for managing system themes in a Linux environment.

## Scripts Overview

1. `set_theme.sh` - Core script for saving and applying system theme settings
2. `theme_manager.sh` - User-friendly wrapper for managing named themes

## Usage

### Basic Theme Management (set_theme.sh)

```bash
# Show current theme settings
./set_theme.sh --show

# Save current theme settings
./set_theme.sh --save

# Apply saved theme settings
./set_theme.sh --apply
```

### Managing Named Themes (theme_manager.sh)

```bash
# Show current theme settings
./theme_manager.sh show

# Save current theme with a name
./theme_manager.sh save <theme_name>

# List all saved themes
./theme_manager.sh list

# Apply a saved theme
./theme_manager.sh apply <theme_name>
```

## Theme Settings

The scripts manage the following theme settings:

- GTK Theme
- Color Scheme
- Icon Theme
- Cursor Theme
- Font
- Text Scaling Factor

## Files and Directories

- `~/.config/awesome/themes/settings/current_theme.conf` - Current theme configuration
- `~/.config/awesome/themes/settings/themes/` - Directory containing named theme configurations
- `~/.config/awesome/logs/theme_settings.log` - Log file for set_theme.sh
- `~/.config/awesome/logs/theme_manager.log` - Log file for theme_manager.sh

## Integration with Other Systems

To automatically apply your theme at startup, you can add the following to your startup scripts:

```bash
# Apply the default saved theme
~/.config/awesome/scripts/set_theme.sh --apply

# Or apply a specific named theme
~/.config/awesome/scripts/theme_manager.sh apply <theme_name>
```

## Troubleshooting

If you encounter issues:

1. Check the log files:
   ```bash
   cat ~/.config/awesome/logs/theme_settings.log
   cat ~/.config/awesome/logs/theme_manager.log
   ```

2. Ensure the scripts have execute permissions:
   ```bash
   chmod +x ~/.config/awesome/scripts/set_theme.sh
   chmod +x ~/.config/awesome/scripts/theme_manager.sh
   ```

3. Verify that gsettings is available on your system. 