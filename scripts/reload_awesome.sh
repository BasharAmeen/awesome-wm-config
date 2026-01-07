#!/bin/bash

# Script to reload Awesome WM configuration

echo "Reloading Awesome WM..."
echo 'awesome.restart()' | awesome-client 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Awesome WM reloaded successfully!"
else
    echo "✗ Failed to reload. You can also use: Mod+Ctrl+r"
fi

