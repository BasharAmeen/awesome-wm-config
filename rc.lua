--[[

     Awesome WM configuration template
     github.com/lcpz

--]]

-- {{{ Required libraries

-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

local gears         = require("gears")
local awful         = require("awful")
                      require("awful.autofocus")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local lain          = require("lain")
-- local menubar       = require("menubar")
local freedesktop   = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup")
-- local cyclefocus = require('cyclefocus')
require("awful.hotkeys_popup.keys")
local mytable       = awful.util.table or gears.table -- 4.{0,1} compatibility
local dpi           = require("beautiful.xresources").apply_dpi

-- }}}

-- {{{ Helper functions for theming
-- Helper function to add alpha channel to colors
local function add_alpha(color, alpha)
    if color:find("#") == 1 then
        local r, g, b
        -- Check if it's a 6-digit or 3-digit hex code
        if #color == 7 then -- #RRGGBB format
            r = tonumber("0x"..color:sub(2,3))
            g = tonumber("0x"..color:sub(4,5))
            b = tonumber("0x"..color:sub(6,7))
        elseif #color == 4 then -- #RGB format
            r = tonumber("0x"..color:sub(2,2)..color:sub(2,2))
            g = tonumber("0x"..color:sub(3,3)..color:sub(3,3))
            b = tonumber("0x"..color:sub(4,4)..color:sub(4,4))
        else
            return color
        end
        
        if r and g and b then
            -- Convert alpha from 0-1 to 0-255 and format as hex
            local a = math.floor(alpha * 255)
            return string.format("#%02x%02x%02x%02x", r, g, b, a)
        end
    end
    return color
end

-- Create a color palette to ensure consistency
local theme_colors = {
    bg_normal = beautiful.bg_normal or "#222222",
    bg_focus = beautiful.bg_focus or "#535d6c",
    bg_urgent = beautiful.bg_urgent or "#ff0000",
    fg_normal = beautiful.fg_normal or "#aaaaaa",
    fg_focus = beautiful.fg_focus or "#ffffff",
    fg_urgent = beautiful.fg_urgent or "#ffffff",
    border_normal = beautiful.border_normal or "#000000",
    border_focus = beautiful.border_focus or "#535d6c"
}

-- Helper function to create theme-consistent rounded containers
local function create_rounded_container(widget, bg_color, fg_color, radius)
    local container = wibox.container.background()
    container.bg = bg_color
    container.fg = fg_color
    container.shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, radius or 4)
    end
    container.widget = widget
    return container
end
-- }}}

-- {{{ Error handling

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify {
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    }
end

-- Handle runtime errors after startup
do
    local in_error = false

    awesome.connect_signal("debug::error", function (err)
        if in_error then return end

        in_error = true

        naughty.notify {
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err)
        }

        in_error = false
    end)
end

-- Customize notifications
naughty.config.padding = 15
naughty.config.spacing = 5

-- Custom notification styles with transparency and rounded corners
naughty.config.presets.normal = {
    timeout = 5,
    position = "top_right",
    bg = add_alpha(theme_colors.bg_normal, 0.8),
    fg = theme_colors.fg_normal,
    border_width = 2,
    border_color = add_alpha(theme_colors.border_normal, 0.7),
    margin = 10,
    opacity = 0.9,
    shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, 8)
    end
}

naughty.config.presets.low = gears.table.clone(naughty.config.presets.normal)
naughty.config.presets.critical = {
    timeout = 0,
    bg = add_alpha(theme_colors.bg_urgent, 0.8),
    fg = theme_colors.fg_urgent,
    border_width = 2,
    border_color = add_alpha(theme_colors.border_focus, 0.9),
    margin = 10,
    opacity = 0.9,
    shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, 8)
    end
}

-- }}}

-- {{{ Autostart windowless processes

-- This function will run once every time Awesome is started
local function run_once(cmd_arr)
    for _, cmd in ipairs(cmd_arr) do
        awful.spawn.with_shell(string.format("pgrep -u $USER -fx '%s' > /dev/null || (%s)", cmd, cmd))
    end
end

run_once({ "urxvtd", "unclutter -root" }) -- comma-separated entries

-- This function implements the XDG autostart specification
--[[
awful.spawn.with_shell(
    'if (xrdb -query | grep -q "^awesome\\.started:\\s*true$"); then exit; fi;' ..
    'xrdb -merge <<< "awesome.started:true";' ..
    -- list each of your autostart commands, followed by ; inside single quotes, followed by ..
    'dex --environment Awesome --autostart --search-paths "$XDG_CONFIG_DIRS/autostart:$XDG_CONFIG_HOME/autostart"' -- https://github.com/jceb/dex
)
--]]

-- }}}

-- {{{ Variable definitions


local themes = {
    "blackburn",       -- 1
    "copland",         -- 2
    "dremora",         -- 3
    "holo",            -- 4
    "multicolor",      -- 5
    "powerarrow",      -- 6
    "powerarrow-dark", -- 7
    "rainbow",         -- 8
    "steamburn",       -- 9
    "vertex"           -- 10
}

local chosen_theme = themes[7]
local modkey       = "Mod4"
local altkey       = "Mod1"

-- mine:
terminal = "alacritty"
editor = os.getenv("EDITOR") or "vscodium"
editor_cmd = terminal .. " -e " .. editor
-- local terminal     = "urxvtc"
local vi_focus     = false -- vi-like client focus https://github.com/lcpz/awesome-copycats/issues/275
local cycle_prev   = true  -- cycle with only the previously focused client or all https://github.com/lcpz/awesome-copycats/issues/274
-- local editor       = os.getenv("EDITOR") or "nvim"
local browser      = "firefox"

awful.util.terminal = terminal
awful.util.tagnames = { "1", "2", "3", "4", "5","6", "7" }
awful.layout.layouts = {
    awful.layout.suit.spiral,
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    --awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral.dwindle,
    --awful.layout.suit.max,
    --awful.layout.suit.max.fullscreen,
    --awful.layout.suit.magnifier,
    --awful.layout.suit.corner.nw,
    --awful.layout.suit.corner.ne,
    --awful.layout.suit.corner.sw,
    --awful.layout.suit.corner.se,
    --lain.layout.cascade,
    --lain.layout.cascade.tile,
    --lain.layout.centerwork,
    --lain.layout.centerwork.horizontal,
    --lain.layout.termfair,
    --lain.layout.termfair.center
}

lain.layout.termfair.nmaster           = 3
lain.layout.termfair.ncol              = 1
lain.layout.termfair.center.nmaster    = 3
lain.layout.termfair.center.ncol       = 1
lain.layout.cascade.tile.offset_x      = 2
lain.layout.cascade.tile.offset_y      = 32
lain.layout.cascade.tile.extra_padding = 5
lain.layout.cascade.tile.nmaster       = 5
lain.layout.cascade.tile.ncol          = 2

-- Enhanced taglist with larger font and better styling
local taglist_square_size = dpi(5)
awful.util.taglist_buttons = mytable.join(
 
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t)
        if client.focus then client.focus:move_to_tag(t) end
    end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t)
        if client.focus then client.focus:toggle_tag(t) end
    end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

beautiful.init(string.format("%s/.config/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme))

-- Load custom modules after theme initialization
local system_dashboard = require("modules.widgets.system_dashboard")
local smart_layout = require("modules.smart_layout")
local rules = require("modules.rules")
-- local window_grouping = require("modules.window_grouping")

-- Create a custom system monitor widget
local system_monitor = {}

-- Default colors for system monitor widgets (backup if beautiful is not loaded yet)
local default_bg_focus = "#535d6c"
local default_bg_urgent = "#ff0000"

-- CPU widget
system_monitor.cpu = wibox.widget {
    {
        {
            id = "icon",
            text = " ", -- FontAwesome icon
            font = "FontAwesome 11",
            widget = wibox.widget.textbox,
        },
        {
            id = "text",
            text = "CPU: N/A",
            widget = wibox.widget.textbox,
        },
        layout = wibox.layout.fixed.horizontal,
        spacing = 5,
    },
    bg = (beautiful.bg_focus or default_bg_focus) .. "40",
    shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, 4) end,
    widget = wibox.container.background,
}

-- Memory widget
system_monitor.memory = wibox.widget {
    {
        {
            id = "icon",
            text = " ", -- FontAwesome icon
            font = "FontAwesome 11",
            widget = wibox.widget.textbox,
        },
        {
            id = "text",
            text = "RAM: N/A",
            widget = wibox.widget.textbox,
        },
        layout = wibox.layout.fixed.horizontal,
        spacing = 5,
    },
    bg = (beautiful.bg_focus or default_bg_focus) .. "40",
    shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, 4) end,
    widget = wibox.container.background,
}

-- Battery widget
system_monitor.battery = wibox.widget {
    {
        {
            id = "icon",
            text = " ", -- FontAwesome icon
            font = "FontAwesome 11",
            widget = wibox.widget.textbox,
        },
        {
            id = "text",
            text = "BAT: N/A",
            widget = wibox.widget.textbox,
        },
        layout = wibox.layout.fixed.horizontal,
        spacing = 5,
    },
    bg = (beautiful.bg_focus or default_bg_focus) .. "40",
    shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, 4) end,
    widget = wibox.container.background,
}

-- Update CPU usage
local cpu_update_timer = gears.timer {
    timeout = 5,
    callback = function()
        awful.spawn.easy_async_with_shell("grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}'", function(stdout)
            local cpu_usage = tonumber(stdout) or 0
            local cpu_text = string.format("CPU: %.1f%%", cpu_usage)
            local cpu_widget = system_monitor.cpu:get_children_by_id("text")[1]
            if cpu_widget then
                cpu_widget.text = cpu_text
            end
            
            -- Change color based on usage
            if cpu_usage > 80 then
                system_monitor.cpu.bg = (beautiful.bg_urgent or default_bg_urgent) .. "60"
            elseif cpu_usage > 50 then
                system_monitor.cpu.bg = "#f0932b60" -- Orange with transparency
            else
                system_monitor.cpu.bg = (beautiful.bg_focus or default_bg_focus) .. "40"
            end
        end)
    end
}

-- Update Memory usage
local memory_update_timer = gears.timer {
    timeout = 5,
    callback = function()
        awful.spawn.easy_async_with_shell("free -m | grep 'Mem:' | awk '{print $3/$2 * 100.0}'", function(stdout)
            local mem_usage = tonumber(stdout) or 0
            local mem_text = string.format("RAM: %.1f%%", mem_usage)
            local mem_widget = system_monitor.memory:get_children_by_id("text")[1]
            if mem_widget then
                mem_widget.text = mem_text
            end
            
            -- Change color based on usage
            if mem_usage > 80 then
                system_monitor.memory.bg = (beautiful.bg_urgent or default_bg_urgent) .. "60"
            elseif mem_usage > 50 then
                system_monitor.memory.bg = "#f0932b60" -- Orange with transparency
            else
                system_monitor.memory.bg = (beautiful.bg_focus or default_bg_focus) .. "40"
            end
        end)
    end
}

-- Update Battery status
local battery_update_timer = gears.timer {
    timeout = 30,
    callback = function()
        -- Check if battery exists
        awful.spawn.easy_async_with_shell("ls /sys/class/power_supply/BAT*", function(bat_stdout)
            if bat_stdout ~= "" then
                awful.spawn.easy_async_with_shell("cat /sys/class/power_supply/BAT*/capacity", function(stdout)
                    local battery_level = tonumber(stdout) or 0
                    awful.spawn.easy_async_with_shell("cat /sys/class/power_supply/BAT*/status", function(status_stdout)
                        local charging = status_stdout:match("Charging") ~= nil
                        local bat_icon = system_monitor.battery:get_children_by_id("icon")[1]
                        local bat_text = system_monitor.battery:get_children_by_id("text")[1]
                        
                        -- Update icon based on battery level and charging status
                        if bat_icon and bat_text then
                            local icon = " " -- Default icon
                            if charging then
                                icon = " " -- Charging icon
                                bat_text.text = string.format("BAT: %d%% (Charging)", battery_level)
                            else
                                if battery_level < 20 then
                                    icon = " " -- Low battery
                                elseif battery_level < 50 then
                                    icon = " " -- Medium battery
                                else
                                    icon = " " -- Full battery
                                end
                                bat_text.text = string.format("BAT: %d%%", battery_level)
                            end
                            bat_icon.text = icon
                            
                            -- Change color based on battery level
                            if not charging and battery_level < 20 then
                                system_monitor.battery.bg = (beautiful.bg_urgent or default_bg_urgent) .. "60"
                            elseif not charging and battery_level < 40 then
                                system_monitor.battery.bg = "#f0932b60" -- Orange with transparency
                            else
                                system_monitor.battery.bg = (beautiful.bg_focus or default_bg_focus) .. "40"
                            end
                        end
                    end)
                end)
            else
                -- No battery found
                local bat_text = system_monitor.battery:get_children_by_id("text")[1]
                if bat_text then
                    bat_text.text = "No Battery"
                end
                system_monitor.battery.visible = false
            end
        end)
    end
}

-- Start the timer after beautiful has been initialized
cpu_update_timer:start()
memory_update_timer:start()
battery_update_timer:start()

-- }}}

-- {{{ Menu

-- Create a launcher widget and a main menu
local myawesomemenu = {
   { "Hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "Manual", string.format("%s -e man awesome", terminal) },
   { "Edit config", string.format("%s -e %s %s", terminal, editor, awesome.conffile) },
   { "Restart", awesome.restart },
   { "Quit", function() awesome.quit() end },
}

awful.util.mymainmenu = freedesktop.menu.build {
    before = {
        { "Awesome", myawesomemenu, beautiful.awesome_icon },
        -- other triads can be put here
    },
    after = {
        { "Open terminal", terminal },
        -- other triads can be put here
        
    }
}

-- Hide the menu when the mouse leaves it
--[[
awful.util.mymainmenu.wibox:connect_signal("mouse::leave", function()
    if not awful.util.mymainmenu.active_child or
       (awful.util.mymainmenu.wibox ~= mouse.current_wibox and
       awful.util.mymainmenu.active_child.wibox ~= mouse.current_wibox) then
        awful.util.mymainmenu:hide()
    else
        awful.util.mymainmenu.active_child.wibox:connect_signal("mouse::leave",
        function()
            if awful.util.mymainmenu.wibox ~= mouse.current_wibox then
                awful.util.mymainmenu:hide()
            end
        end)
    end
end)
--]]

-- Set the Menubar terminal for applications that require it
--menubar.utils.terminal = terminal

-- }}}

-- {{{ Screen

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", function(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end)

-- No borders when rearranging only 1 non-floating or maximized client
screen.connect_signal("arrange", function (s)
    local only_one = #s.tiled_clients == 1
    for _, c in pairs(s.clients) do
        if only_one and not c.floating or c.maximized or c.fullscreen then
            c.border_width = 0
        else
            c.border_width = beautiful.border_width
        end
    end
end)

-- Create a wibox for each screen and add it
awful.screen.connect_for_each_screen(function(s) beautiful.at_screen_connect(s) end)

-- }}}

-- {{{ Mouse bindings

root.buttons(mytable.join(
    awful.button({ }, 3, function () awful.util.mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

-- }}}

-- {{{ Key bindings

-- Create a progressbar widget with modern styling
local volume_progressbar = wibox.widget {
    max_value        = 100,
    value            = 50,
    forced_height    = dpi(10),
    forced_width     = dpi(200),
    paddings         = dpi(1),
    shape            = gears.shape.rounded_bar,
    bar_shape        = gears.shape.rounded_bar,
    color = {
        type = "linear",
        from = { 0, 0 },
        to = { dpi(200), 0 },
        stops = {
            { 0, beautiful.bg_focus },
            { 0.5, beautiful.fg_focus },
            { 1, add_alpha(beautiful.bg_urgent, 0.7) }
        }
    },
    background_color = add_alpha(beautiful.bg_normal, 0.3),
    border_width     = dpi(1),
    border_color     = beautiful.border_focus,
    widget           = wibox.widget.progressbar,
}

-- Create a volume icon with modern styling
local volume_icon = wibox.widget {
    font = "FontAwesome 24", -- Larger icon
    align = "center",
    valign = "center",
    widget = wibox.widget.textbox,
}

-- Create a volume percentage text with improved styling
local volume_text = wibox.widget {
    font = beautiful.font .. " 14", -- Larger text
    align = "center",
    valign = "center",
    widget = wibox.widget.textbox,
}

-- Function to update volume icon based on level with modern aesthetics
local function update_volume_icon(volume, is_muted)
    -- Try to use Nerd Font icons first
    awful.spawn.easy_async_with_shell("fc-list | grep -i 'nerd\\|awesome'", function(stdout)
        local has_special_fonts = stdout ~= ""
        
        if has_special_fonts then
            -- Use Nerd Font or FontAwesome icons with color
            if is_muted or volume == 0 then
                volume_icon.markup = "<span foreground='" .. beautiful.fg_urgent .. "' font='24px'>󰝟</span>"
            elseif volume < 30 then
                volume_icon.markup = "<span foreground='" .. beautiful.fg_normal .. "' font='24px'>󰕿</span>"
            elseif volume < 70 then
                volume_icon.markup = "<span foreground='" .. beautiful.fg_normal .. "' font='24px'>󰖀</span>"
            else
                volume_icon.markup = "<span foreground='" .. beautiful.fg_normal .. "' font='24px'>󰕾</span>"
            end
        else
            -- Fallback to FontAwesome icons
            if is_muted or volume == 0 then
                volume_icon.markup = "<span foreground='" .. beautiful.fg_urgent .. "' font='24px'></span>" -- fa-volume-mute
            elseif volume < 30 then
                volume_icon.markup = "<span foreground='" .. beautiful.fg_normal .. "' font='24px'></span>" -- fa-volume-down
            elseif volume < 70 then
                volume_icon.markup = "<span foreground='" .. beautiful.fg_normal .. "' font='24px'></span>" -- fa-volume-down
            else
                volume_icon.markup = "<span foreground='" .. beautiful.fg_normal .. "' font='24px'></span>" -- fa-volume-up
            end
        end
        
        -- Update the volume text with modern styling
        volume_text.markup = "<span foreground='" .. beautiful.fg_focus .. 
                            "' font='" .. beautiful.font .. " 14'>" .. volume .. "%</span>"
    end)
end

-- Combined layout for the volume widget with enhanced styling
local volume_widget = wibox.widget {
    {
        {
            {
                volume_icon,
                right = dpi(12),
                widget = wibox.container.margin
            },
            nil,
            {
                volume_text,
                left = dpi(12),
                widget = wibox.container.margin
            },
            layout = wibox.layout.align.horizontal
        },
        bottom = dpi(10),
        widget = wibox.container.margin
    },
    {
        volume_progressbar,
        top = dpi(5),
        bottom = dpi(10),
        left = dpi(10),
        right = dpi(10),
        widget = wibox.container.margin
    },
    layout = wibox.layout.fixed.vertical
}

-- Add a modern glass effect for better visibility
local volume_with_shadow = wibox.container.background(
    wibox.container.margin(volume_widget, dpi(25), dpi(25), dpi(20), dpi(20)),
    beautiful.bg_normal .. "B3" -- 70% opacity
)

-- Add rounded corners and subtle border
volume_with_shadow.shape = function(cr, w, h)
    gears.shape.rounded_rect(cr, w, h, dpi(15))
end
volume_with_shadow.border_width = dpi(1)
volume_with_shadow.border_color = beautiful.border_focus .. "40" -- Subtle border

-- Create the volume display popup with enhanced styling
local volume_popup = awful.popup {
    widget = volume_with_shadow,
    ontop = true,
    visible = false,
    type = "notification",
    shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, dpi(15))
    end,
    bg = "#00000000", -- Fully transparent background
    placement = awful.placement.centered,
    width = dpi(300),
    height = dpi(120),
    shape_shadow = false,       -- Disable default shadow
    shadow_offset_x = 0,        -- No shadow offset
    shadow_offset_y = 0,
    shadow_blur_sigma = 0      -- Remove shadow blur
}

-- Animation for smooth transitions with enhanced easing
local animation_steps = 20 -- More steps for smoother animation
local animation_timeout = 0.008 -- Slightly faster for more responsive feel
local animation_target_value = 0
local animation_current_step = 0
local animation_timer = nil
local hide_volume_timer = nil -- Variable to store the timer for hiding volume popup

-- Function to animate the progress bar with easing function
local function animate_progressbar(target)
    if animation_timer then
        animation_timer:stop()
    end
    
    animation_target_value = target
    animation_current_step = 0
    local start_value = volume_progressbar.value
    
    animation_timer = gears.timer.start_new(animation_timeout, function()
        animation_current_step = animation_current_step + 1
        local progress = animation_current_step / animation_steps
        
        -- Easing function for smoother animation (ease out quad)
        local eased_progress = -(progress * (progress - 2))
        local new_value = start_value + (animation_target_value - start_value) * eased_progress
        
        volume_progressbar.value = new_value
        
        if animation_current_step >= animation_steps then
            return false -- Stop the timer
        end
        return true -- Continue the timer
    end)
end

-- Function to show the volume popup with fade-in effect
local function show_volume_popup()
    -- Check if muted
    awful.spawn.easy_async_with_shell("amixer get Master | grep '\\[off\\]'", function(stdout_muted)
        local is_muted = stdout_muted ~= ""
        
        -- Get volume level
        awful.spawn.easy_async_with_shell("amixer get Master", function(stdout)
            local volume = tonumber(stdout:match("(%d?%d?%d)%%")) or 0
            update_volume_icon(volume, is_muted)
            
            if is_muted then
                -- Set the progressbar to 0 when muted
                animate_progressbar(0)
            else
                animate_progressbar(volume)
            end
            
            -- Show popup with fade-in effect
            volume_popup.opacity = 0
            volume_popup.visible = true
            
            -- Animate opacity for fade-in - make it faster
            local opacity_timer_in = gears.timer {
                timeout = 0.005, -- Faster fade-in (was 0.01)
                call_now = true,
                autostart = true,
                callback = function(t)
                    volume_popup.opacity = volume_popup.opacity + 0.15 -- Bigger steps
                    if volume_popup.opacity >= 1 then
                        t:stop()
                    end
                end
            }
            
            -- Make sure any existing hide timer is removed
            if hide_volume_timer then
                hide_volume_timer:stop()
            end
            
            -- Hide popup after a delay with fade-out
            hide_volume_timer = gears.timer {
                timeout = 0.8, -- Shorter display time (was 2)
                autostart = true,
                single_shot = true,
                callback = function()
                local opacity_timer_out = gears.timer {
                        timeout = 0.005, -- Faster fade-out (was 0.01)
                    call_now = true,
                    autostart = true,
                    callback = function(t)
                            volume_popup.opacity = volume_popup.opacity - 0.15 -- Bigger steps
                        if volume_popup.opacity <= 0 then
                            volume_popup.visible = false
                            t:stop()
                        end
                    end
                }
                end
            }
            
            -- Failsafe: ensure popup is hidden after 2 seconds regardless of animation
            gears.timer {
                timeout = 2, -- Reduced from 5
                autostart = true,
                single_shot = true,
                callback = function()
                    volume_popup.visible = false
                end
            }
        end)
    end)
end

-- Replace the original show_progressbar function with the new one
show_progressbar = show_volume_popup

-- Modify the wibox transparency and styling
local wibox_opacity = "90" -- More transparency for glass effect (90 = ~35% opacity)

-- Apply transparency to wiboxes created by beautiful
local original_at_screen_connect = beautiful.at_screen_connect
beautiful.at_screen_connect = function(s)
    original_at_screen_connect(s)
    
    -- Add transparency to wibox with glass effect
    if s.mywibox then
        s.mywibox.bg = beautiful.bg_normal .. wibox_opacity
        
        -- Add drop shadow for depth
        s.mywibox.shape = function(cr, w, h)
            gears.shape.partially_rounded_rect(cr, w, h, false, false, true, true, dpi(12))
        end
        
        -- Apply smooth box blur effect when window is under the wibox
        s.mywibox:connect_signal("request::display", function(w)
            w.opacity = 0.9 -- Slight transparency for subtle effect
        end)
    end
    
    -- Apply modern styling to bottom wibox if it exists
    if s.mybottomwibox then
        s.mybottomwibox.bg = beautiful.bg_normal .. wibox_opacity
        
        -- Add drop shadow and rounded corners
        s.mybottomwibox.shape = function(cr, w, h)
            gears.shape.partially_rounded_rect(cr, w, h, true, true, false, false, dpi(12))
        end
        
        -- Apply glass effect
        s.mybottomwibox:connect_signal("request::display", function(w)
            w.opacity = 0.9
        end)
    end
    
    -- Find the taglist widget in screen setup
    local taglist = s.mywibox:get_children_by_id("taglist")[1]
    if taglist then
        -- Enhanced appearance for taglist
        local new_taglist = awful.widget.taglist {
            screen = s,
            filter = awful.widget.taglist.filter.all,
            style = {
                shape = gears.shape.rounded_rect,
                font = beautiful.font .. " 14", -- Larger font for tags
            },
            layout = {
                spacing = dpi(10),
                layout = wibox.layout.fixed.horizontal
            },
            widget_template = {
                {
                    {
                        {
                            id = 'text_role',
                            widget = wibox.widget.textbox,
                        },
                        margins = dpi(10), -- Increased padding
                        widget = wibox.container.margin,
                    },
                    id = 'background_role',
                    widget = wibox.container.background,
                },
                forced_width = dpi(40), -- Fixed width for consistent sizing
                forced_height = dpi(40), -- Fixed height for consistent sizing
                create_callback = function(self, tag, index, tags)
                    self:get_children_by_id('text_role')[1].align = "center"
                    self:connect_signal('mouse::enter', function()
                        if self.bg ~= beautiful.bg_focus then
                            self.backup = self.bg
                            self.has_backup = true
                        end
                        self.bg = beautiful.bg_focus .. "99"
                    end)
                    self:connect_signal('mouse::leave', function()
                        if self.has_backup then self.bg = self.backup end
                    end)
                end,
                widget = wibox.container.background,
            },
            buttons = awful.util.taglist_buttons
        }
        
        -- Replace the old taglist with the enhanced one
        local taglist_container = taglist.parent
        if taglist_container then
            taglist_container:replace_widget(taglist, new_taglist)
        end
    end
    
    -- Make systray collapsed by default
    local systray = s.mywibox:get_children_by_id("systray")[1]
    if systray then
        -- Create a toggle button with an icon
        local systray_toggle = wibox.widget {
            {
                text = "󰀶", -- Icon for tray toggle (use a different one if this doesn't show up correctly)
                font = "FontAwesome 14",
                align = "center",
                widget = wibox.widget.textbox,
            },
            bg = beautiful.bg_normal .. "80",
            widget = wibox.container.background,
        }
        
        -- Style the toggle button
        systray_toggle.shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(4))
        end
        
        -- Add margins
        local systray_toggle_with_margin = wibox.widget {
            systray_toggle,
            left = dpi(5),
            right = dpi(5),
            top = dpi(2),
            bottom = dpi(2),
            widget = wibox.container.margin
        }
        
        -- Set up expanded state for systray
        local systray_visible = false
        systray.visible = systray_visible
        
        -- Toggle systray visibility when clicked
        systray_toggle:connect_signal("button::press", function(_, _, _, button)
            if button == 1 then -- Left click
                systray_visible = not systray_visible
                systray.visible = systray_visible
                
                -- Change background color to indicate state
                if systray_visible then
                    systray_toggle.bg = beautiful.bg_focus .. "80"
                    systray_toggle.fg = beautiful.fg_focus
                else
                    systray_toggle.bg = beautiful.bg_normal .. "80"
                    systray_toggle.fg = beautiful.fg_normal
                end
            end
        end)
        
        -- Add the toggle button next to the systray
        local systray_container = systray.parent
        if systray_container then
            -- Create a layout that contains both the toggle and the systray
            local tray_layout = wibox.layout.fixed.horizontal()
            tray_layout:add(systray_toggle_with_margin)
            tray_layout:add(systray)
            
            -- Replace the systray with the new layout
            systray_container:replace_widget(systray, tray_layout)
        end
    end
end

-- Add a scroll handler for the wibox with smooth animations
awful.screen.connect_for_each_screen(function(s)
    if s.mywibox then
        s.mywibox.visible = true -- Ensure wibox is visible by default
        
        -- Add hover effect to wibox (slightly more opaque on hover)
        s.mywibox:connect_signal("mouse::enter", function()
            s.mywibox.bg = beautiful.bg_normal .. "A0" -- ~63% opacity on hover
        end)
        
        s.mywibox:connect_signal("mouse::leave", function()
            s.mywibox.bg = beautiful.bg_normal .. wibox_opacity -- Back to normal opacity
        end)
    end
end)

globalkeys = mytable.join(
-- alt + tab to switch between windows
-- modkey+Tab: cycle through all clients.
-- awful.key({ altkey }, "Tab", function(c)
--     cyclefocus.cycle({modifier="Super_L"})
-- end),
-- -- altkey+Shift+Tab: backwards
-- awful.key({ altkey, "Shift" }, "Tab", function(c)
--     cyclefocus.cycle({modifier="Super_L"})
-- end),
 




-- Destroy all notifications
    awful.key({ altkey,           }, "space", function() naughty.destroy_all_notifications() end,
              {description = "destroy all notifications", group = "hotkeys"}),
              
    -- togale enable/disable_icon all notifications
    -- show a notification with the current state before toggle enable/disable
    awful.key({ altkey, "Control" }, "space", function()
        local n_enabled = naughty.is_suspended()
        naughty.notify {
            preset = naughty.config.presets.normal,
            title = "Notifications",
            text = "Notifications are " .. (n_enabled and "enabled" or "disabled"),
        }
        naughty.toggle()
    end, {description = "toggle enable/disable all notifications", group = "hotkeys"}),
   
     
    
              -- Take a screenshot
    -- https://github.com/lcpz/dots/blob/master/bin/screenshot
    -- awful.key({ modkey, "Shift" }, "s", function() os.execute("flameshot gui") end,
    --           {description = "take a screenshot", group = "hotkeys"}),
    -- Take a screenshot with Flameshot using a slight delay
    awful.key({ modkey, "Shift" }, "s", function ()
        -- Run the script using awful.spawn.easy_async_with_shell
        awful.spawn.easy_async_with_shell([[
            focusedwindow=$(xdotool getactivewindow)
            flameshot gui >/dev/null
            if [ "$focusedwindow" == "$(xdotool getactivewindow)" ]
            then
                xdotool windowfocus $focusedwindow
            fi
        ]], function()
            -- The script is done, you can add any additional code here if needed
        end)
    end, {description = "take a screenshot", group = "mine"}),

    -- X screen locker
    awful.key({ altkey, "Control" }, "l", function () os.execute(scrlocker) end,
              {description = "lock screen", group = "hotkeys"}),

    -- Show help
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),

    -- Tag browsing
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    -- Non-empty tag browsing
    -- awful.key({ altkey }, "Left", function () lain.util.tag_view_nonempty(-1) end,
    --           {description = "view  previous nonempty", group = "tag"}),
    -- awful.key({ altkey }, "Right", function () lain.util.tag_view_nonempty(1) end,
    --           {description = "view  previous nonempty", group = "tag"}),

    -- Default client focus
    awful.key({ altkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ altkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),

    -- By-direction client focus
    awful.key({ modkey }, "j",
        function()
            awful.client.focus.global_bydirection("down")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus down", group = "client"}),
    awful.key({ modkey }, "k",
        function()
            awful.client.focus.global_bydirection("up")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus up", group = "client"}),
    awful.key({ modkey }, "h",
        function()
            awful.client.focus.global_bydirection("left")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus left", group = "client"}),
    awful.key({ modkey }, "l",
        function()
            awful.client.focus.global_bydirection("right")
            if client.focus then client.focus:raise() end
        end,
        {description = "focus right", group = "client"}),

    -- Menu
    awful.key({ modkey,           }, "w", function () awful.util.mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            if cycle_prev then
                awful.client.focus.history.previous()
            else
                awful.client.focus.byidx(-1)
            end
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "cycle with previous/go back", group = "client"}),

    -- Show/hide wibox
    awful.key({ modkey }, "b", function ()
            for s in screen do
                s.mywibox.visible = not s.mywibox.visible
                if s.mybottomwibox then
                    s.mybottomwibox.visible = not s.mybottomwibox.visible
                end
            end
        end,
        {description = "toggle wibox", group = "awesome"}),

    -- On-the-fly useless gaps change
    awful.key({ altkey, "Control" }, "+", function () lain.util.useless_gaps_resize(1) end,
              {description = "increment useless gaps", group = "tag"}),
    awful.key({ altkey, "Control" }, "-", function () lain.util.useless_gaps_resize(-1) end,
              {description = "decrement useless gaps", group = "tag"}),

    -- Dynamic tagging
    awful.key({ modkey, "Shift" }, "n", function () lain.util.add_tag() end,
              {description = "add new tag", group = "tag"}),
    awful.key({ modkey, "Shift" }, "r", function () lain.util.rename_tag() end,
              {description = "rename tag", group = "tag"}),
    awful.key({ modkey, "Shift" }, "Left", function () lain.util.move_tag(-1) end,
              {description = "move tag to the left", group = "tag"}),
    awful.key({ modkey, "Shift" }, "Right", function () lain.util.move_tag(1) end,
              {description = "move tag to the right", group = "tag"}),
    awful.key({ modkey, "Shift" }, "d", function () lain.util.delete_tag() end,
              {description = "delete tag", group = "tag"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey, altkey    }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey, altkey    }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n", function ()
        local c = awful.client.restore()
        -- Focus restored client
        if c then
            c:emit_signal("request::activate", "key.unminimize", {raise = true})
        end
    end, {description = "restore minimized", group = "client"}),

    -- Dropdown application
    awful.key({ modkey, }, "z", function () awful.screen.focused().quake:toggle() end,
              {description = "dropdown application", group = "launcher"}),

    -- Widgets popups
    awful.key({ altkey, }, "c", function () if beautiful.cal then beautiful.cal.show(7) end end,
              {description = "show calendar", group = "widgets"}),
    awful.key({ altkey, }, "h", function () if beautiful.fs then beautiful.fs.show(7) end end,
              {description = "show filesystem", group = "widgets"}),
    awful.key({ altkey, }, "w", function () if beautiful.weather then beautiful.weather.show(7) end end,
              {description = "show weather", group = "widgets"}),

    -- Screen brightness
    awful.key({ }, "XF86MonBrightnessUp", function () os.execute("light -A 1") end,
              {description = "+1%", group = "hotkeys"}),
    awful.key({ }, "XF86MonBrightnessDown", function () os.execute("light -U 1") end,
              {description = "-1%", group = "hotkeys"}),

    -- ALSA volume control
    -- Update the volume control hotkeys to show the slider
    awful.key({ modkey }, "Up",
    function ()
        os.execute(string.format("amixer -q set %s 1%%+", beautiful.volume.channel))
        beautiful.volume.update()
        show_volume_popup()
    end,
    {description = "volume up", group = "hotkeys"}),
    awful.key({ modkey }, "Down",
    function ()
        os.execute(string.format("amixer -q set %s 1%%-", beautiful.volume.channel))
        beautiful.volume.update()
        show_volume_popup()
    end,
    {description = "volume down", group = "hotkeys"}),
    awful.key({ modkey }, "m",
    function ()
        os.execute(string.format("amixer -q set %s toggle", beautiful.volume.togglechannel or beautiful.volume.channel))
        beautiful.volume.update()
        show_volume_popup()
    end,
    {description = "toggle mute", group = "hotkeys"}),
    awful.key({ modkey, "Control" }, "m",
    function ()
        os.execute(string.format("amixer -q set %s 100%%", beautiful.volume.channel))
        beautiful.volume.update()
        show_volume_popup()
    end,
    {description = "volume 100%", group = "hotkeys"}),
    awful.key({ modkey, "Control" }, "0",
    function ()
        os.execute(string.format("amixer -q set %s 0%%", beautiful.volume.channel))
        beautiful.volume.update()
        show_volume_popup()
    end,
    {description = "volume 0%", group = "hotkeys"}),

    -- MPD control
    awful.key({ modkey, "Control" }, "Up",
        function ()
            os.execute("mpc toggle")
            beautiful.mpd.update()
        end,
        {description = "mpc toggle", group = "widgets"}),
    awful.key({ modkey, "Control" }, "Down",
        function ()
            os.execute("mpc stop")
            beautiful.mpd.update()
        end,
        {description = "mpc stop", group = "widgets"}),
    awful.key({ modkey, "Control" }, "Left",
        function ()
            os.execute("mpc prev")
            beautiful.mpd.update()
        end,
        {description = "mpc prev", group = "widgets"}),
    awful.key({ modkey, "Control" }, "Right",
        function ()
            os.execute("mpc next")
            beautiful.mpd.update()
        end,
        {description = "mpc next", group = "widgets"}),
    awful.key({ modkey }, "0",
        function ()
            local common = { text = "MPD widget ", position = "top_middle", timeout = 2 }
            if beautiful.mpd.timer.started then
                beautiful.mpd.timer:stop()
                common.text = common.text .. lain.util.markup.bold("OFF")
            else
                beautiful.mpd.timer:start()
                common.text = common.text .. lain.util.markup.bold("ON")
            end
            naughty.notify(common)
        end,
        {description = "mpc on/off", group = "widgets"}),
    
    -- -- Copy primary to clipboard (terminals to gtk)
    -- awful.key({ modkey }, "c", function () awful.spawn.with_shell("xsel | xsel -i -b") end,
    --           {description = "copy terminal to gtk", group = "hotkeys"}),
    -- -- Copy clipboard to primary (gtk to terminals)
    -- awful.key({ modkey }, "v", function () awful.spawn.with_shell("xsel -b | xsel") end,
    --           {description = "copy gtk to terminal", group = "hotkeys"}),

    -- User programs
    awful.key({ modkey }, "q", function () awful.spawn(browser) end,
              {description = "run browser", group = "launcher"}),

    -- Default
    --[[ Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),
    --]]
    --[[ dmenu
    awful.key({ modkey }, "x", function ()
            os.execute(string.format("dmenu_run -i -fn 'Monospace' -nb '%s' -nf '%s' -sb '%s' -sf '%s'",
            beautiful.bg_normal, beautiful.fg_normal, beautiful.bg_focus, beautiful.fg_focus))
        end,
        {description = "show dmenu", group = "launcher"}),
    --]]
    -- alternatively use rofi, a dmenu-like application with more features
    -- check https://github.com/DaveDavenport/rofi for more details
    --[[ rofi
    awful.key({ modkey }, "x", function ()
            os.execute(string.format("rofi -show %s -theme %s",
            'run', 'dmenu'))
        end,
        {description = "show rofi", group = "launcher"}),
    --]]
    -- Prompt
    awful.key({ modkey }, "r", function () awful.spawn("gmrun") end,
              {description = "run prompt", group = "launcher"}),


    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),

    -- Toggle dark theme with Win+Alt+D
    awful.key({ modkey, altkey }, "d", function()
        awesome.emit_signal("dark_theme::toggle")
        naughty.notify({
            title = "Dark Theme",
            text = "Toggling dark theme for all applications",
            timeout = 2
        })
    end, {description = "toggle dark theme", group = "awesome"}),

    -- Toggle system dashboard
    awful.key({ modkey, "Control" }, "d", function() system_dashboard.toggle() end,
              {description = "toggle system dashboard", group = "mine"}),

    -- Toggle window rules manager
    awful.key({ modkey, "Control" }, "w", function() rules.window_rules_manager.toggle() end,
              {description = "toggle window rules manager", group = "mine"}),

    -- Get current window properties
    awful.key({ modkey, altkey }, "w", function() rules.window_rules_manager.get_focused_window_properties() end,
              {description = "show current window properties", group = "mine"})
)

-- Append window grouping keybindings
-- local window_group_keys = window_grouping.get_group_keybindings({"Mod4", "Control"}, "g")
-- for _, key in ipairs(window_group_keys) do
--     globalkeys = gears.table.join(globalkeys, key)
-- end

clientkeys = mytable.join(
    awful.key({ altkey, "Shift"   }, "m",      lain.util.magnify_client,
              {description = "magnify client", group = "client"}),
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = mytable.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = mytable.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)

-- }}}

-- {{{ Rules

-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     callback = awful.client.setslave,
                     focus = awful.client.focus.filter,
                     raise = true, 
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                     size_hints_honor = false
     },
     -- this function will make the new client the master
     callback = function (c)
        awful.client.setmaster(c)
    end
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"},

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}

-- }}}

-- {{{ Signals

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- Custom
    if beautiful.titlebar_fun then
        beautiful.titlebar_fun(c)
        return
    end

    -- Default
    -- buttons for the titlebar
    local buttons = mytable.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    -- Create a modern, semi-transparent titlebar
    awful.titlebar(c, { size = 32, bg = beautiful.bg_normal .. "CC" }) : setup {
        { -- Left
            {
                awful.titlebar.widget.iconwidget(c),
                margins = 5,
                widget = wibox.container.margin
            },
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                font   = beautiful.font .. " 10",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            {
                awful.titlebar.widget.floatingbutton (c),
                awful.titlebar.widget.maximizedbutton(c),
                awful.titlebar.widget.stickybutton   (c),
                awful.titlebar.widget.ontopbutton    (c),
                awful.titlebar.widget.closebutton    (c),
                spacing = 5,
                layout = wibox.layout.fixed.horizontal()
            },
            margins = 5,
            widget = wibox.container.margin
        },
        layout = wibox.layout.align.horizontal
    }
    
    -- Add rounded corners to the client
    c.shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, 8)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
-- client.connect_signal("mouse::enter", function(c)
--     c:emit_signal("request::activate", "mouse_enter", {raise = vi_focus})
-- end)

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
    if not c.fullscreen then
        c.opacity = 1.0
    end
end)

client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
    if not c.fullscreen and not c.maximized then
        c.opacity = 0.90
    end
end)

-- switch to parent after closing child window
local function backham()
    local s = awful.screen.focused()
    local c = awful.client.focus.history.get(s, 0)
    if c then
        client.focus = c
        c:raise()
    end
end

-- attach to minimized state
client.connect_signal("property::minimized", backham)
-- attach to closed state
client.connect_signal("unmanage", backham)
-- ensure there is always a selected client during tag switching or logins
tag.connect_signal("property::selected", backham)

-- }}}



-- autostart application

-- Apply dark theme
local dark_theme = require("modules.autostart.dark-theme")
dark_theme.init()

-- Initialize smart layout switching
-- smart_layout.init()

-- Initialize window grouping 
-- window_grouping.init()

-- Configure and start picom for visual effects
awful.spawn.easy_async_with_shell("pgrep picom", function(stdout)
    if not stdout or stdout == "" then
        awful.spawn.with_shell("picom --backend glx --vsync --shadow-radius=15 --corner-radius=8 --shadow-opacity=0.85 --active-opacity=1.0 --inactive-opacity=0.90 --shadow-offset-x=-15 --shadow-offset-y=-15 --shadow-color=\"#000000\" -b")
        -- Create picom configuration if it doesn't exist
        awful.spawn.with_shell("mkdir -p ~/.config/picom")
        awful.spawn.with_shell([[
        if [ ! -f ~/.config/picom/picom.conf ]; then
            cat > ~/.config/picom/picom.conf << 'EOF'
# Shadows
shadow = true;
shadow-radius = 15;
shadow-offset-x = -15;
shadow-offset-y = -15;
shadow-opacity = 0.85;
shadow-color = "#000000";

# Fading
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;
fade-delta = 5;

# Transparency / Opacity
inactive-opacity = 0.90;
active-opacity = 1.0;
frame-opacity = 0.9;
inactive-opacity-override = false;

# Window type settings
wintypes:
{
  tooltip = { fade = true; shadow = false; opacity = 0.9; focus = true; };
  dock = { shadow = false; clip-shadow-above = true; };
  dnd = { shadow = false; };
  popup_menu = { opacity = 0.9; };
  dropdown_menu = { opacity = 0.9; };
};

# Corners
corner-radius = 8;
rounded-corners-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'"
];

# Blur
blur-background = true;
blur-method = "dual_kawase";
blur-strength = 5;
blur-background-exclude = [
  "window_type = 'dock'",
  "window_type = 'desktop'"
];
EOF
        fi
        ]])
    end
end)

-- set the wallpaper
awful.spawn.with_shell("bash $HOME/.config/awesome/set_wallpaper.sh")

-- battrey manager
-- awful.spawn.easy_async_with_shell("pgrep cbatticon", function(stdout)
--     if not stdout or stdout == "" then
--         awful.spawn.with_shell("cbatticon")
--     end
-- end)

awful.spawn.easy_async_with_shell("pgrep firefox", function(stdout)
    if not stdout or stdout == "" then
        awful.spawn.with_shell("firefox")
    end
end)

-- clipboard manager
awful.spawn.easy_async_with_shell("pgrep copyq", function(stdout)
    if not stdout or stdout == "" then
        awful.spawn.with_shell("copyq")
    end
end)

-- screenshot
-- awful.spawn.easy_async_with_shell("pgrep flameshot", function(stdout)
--     if not stdout or stdout == "" then
--         awful.spawn.with_shell("flameshot")
--     end
-- end)


-- Network Manager tray icon
awful.spawn.easy_async_with_shell("pgrep nm-applet", function(stdout)
    if not stdout or stdout == "" then
        awful.spawn.with_shell("nm-applet")
    end
end)

-- volumeicon tray icon
-- awful.spawn.easy_async_with_shell("pgrep volumeicon", function(stdout)
--     if not stdout or stdout == "" then
--         awful.spawn.with_shell("volumeicon")
--     end
-- end)
-- screenshot
awful.spawn.easy_async_with_shell("pgrep flameshot", function(stdout)
    if not stdout or stdout == "" then
        awful.spawn.with_shell("flameshot")
    end
end)
awful.spawn.with_shell("xinput set-prop 'DELL09E1:00 04F3:30CB Touchpad' 'libinput Tapping Enabled' 1")
awful.spawn.with_shell("setxkbmap -layout us,ara -option 'grp:alt_shift_toggle'")
awful.spawn.with_shell("eval $(gnome-keyring-daemon --start)")
