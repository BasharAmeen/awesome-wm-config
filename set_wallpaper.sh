#!/bin/bash

if [ -z "$wallpaper_path" ]; then
    wallpaper_path="/mnt/hdd/user_data/pictures/wallpapers/wallpaper_2.png"
fi

feh --bg-scale "$wallpaper_path"