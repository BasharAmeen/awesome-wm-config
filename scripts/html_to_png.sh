#!/bin/bash

# Script to convert HTML wallpaper to PNG
# Requires: chromium or google-chrome

HTML_FILE="$1"
OUTPUT_FILE="$2"
WIDTH="${3:-1920}"
HEIGHT="${4:-1080}"

if [ -z "$HTML_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <html_file> <output_png>"
    echo "Example: $0 wallpapers/awesome_tech_drone.html wallpapers/awesome_tech_drone.png"
    exit 1
fi

# Get absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"

# Resolve HTML file path
if [[ "$HTML_FILE" != /* ]]; then
    HTML_FILE="$CONFIG_DIR/$HTML_FILE"
fi

# Resolve output file path
if [[ "$OUTPUT_FILE" != /* ]]; then
    OUTPUT_FILE="$CONFIG_DIR/$OUTPUT_FILE"
fi

echo "Converting HTML to PNG..."
echo "Input:  $HTML_FILE"
echo "Output: $OUTPUT_FILE"
echo "Size:   ${WIDTH}x${HEIGHT}"

# Check for browser
CHROME=""
if command -v chromium &> /dev/null; then
    CHROME="chromium"
elif command -v google-chrome &> /dev/null; then
    CHROME="google-chrome"
elif command -v chromium-browser &> /dev/null; then
    CHROME="chromium-browser"
else
    echo "Error: Chromium or Google Chrome not found!"
    echo "Please install one of them:"
    echo "  Arch: sudo pacman -S chromium"
    echo "  Ubuntu: sudo apt install chromium-browser"
    exit 1
fi

# NOTE:
# Some Chromium builds produce a screenshot where the last ~80-100px are not the page content.
# We render a slightly taller image then crop back to the exact target size.
RAW_OUT="${OUTPUT_FILE}.raw.png"
PAD_HEIGHT=$((HEIGHT + 140))

# Render
$CHROME --headless --disable-gpu --hide-scrollbars --window-size="${WIDTH},${PAD_HEIGHT}" --screenshot="$RAW_OUT" "file://$HTML_FILE" 2>/dev/null

# Crop (requires ImageMagick: convert/identify)
if command -v convert &> /dev/null; then
    convert "$RAW_OUT" -crop "${WIDTH}x${HEIGHT}+0+0" +repage "$OUTPUT_FILE"
elif command -v magick &> /dev/null; then
    magick "$RAW_OUT" -crop "${WIDTH}x${HEIGHT}+0+0" +repage "$OUTPUT_FILE"
else
    echo "Error: ImageMagick not found (need 'convert' or 'magick' to crop)."
    echo "Arch: sudo pacman -S imagemagick"
    exit 1
fi

rm -f "$RAW_OUT"

if [ $? -eq 0 ] && [ -f "$OUTPUT_FILE" ]; then
    echo "✓ Successfully created: $OUTPUT_FILE"
    echo "✓ Resolution: ${WIDTH}x${HEIGHT}"
else
    echo "✗ Failed to create PNG"
    exit 1
fi

