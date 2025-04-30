-- Dark Theme Autostart Module for AwesomeWM
-- This module ensures dark theme settings are applied on login

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")

local dark_theme = {}

-- Apply dark theme command
local function apply_dark_theme()
    -- Apply Xresources
    awful.spawn.with_shell("xrdb -merge ~/.Xresources")
    
    -- Set GTK3 settings
    awful.spawn.with_shell("gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'")
    awful.spawn.with_shell("gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'")
    awful.spawn.with_shell("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    
    -- Set QT theme
    awful.spawn.with_shell("export QT_STYLE_OVERRIDE=Fusion")
    awful.spawn.with_shell("export QT_QPA_PLATFORMTHEME=qt5ct")
    
    -- Run our dark theme setup script if it exists
    awful.spawn.with_shell("[ -x ~/.dark-theme-setup.sh ] && ~/.dark-theme-setup.sh")
    
    -- Force Firefox dark mode
    awful.spawn.with_shell("echo 'user_pref(\"ui.systemUsesDarkTheme\", 1);' >> ~/.mozilla/firefox/*.default-release/prefs.js")
    
    -- Force Gtk3 dark theme
    awful.spawn.with_shell("echo 'gtk-application-prefer-dark-theme=1' >> ~/.config/gtk-3.0/settings.ini")
end

function dark_theme.init()
    -- Apply dark theme after awesome starts
    gears.timer.start_new(1, function()
        apply_dark_theme()
        return false -- Don't repeat
    end)
    
    -- Also apply dark theme when requested through hotkey (can be connected to a key binding)
    awesome.connect_signal("dark_theme::toggle", function()
        apply_dark_theme()
    end)
end

return dark_theme 