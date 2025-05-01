local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local naughty = require("naughty")
local dpi = require("beautiful.xresources").apply_dpi

-- Window Grouping module
local window_grouping = {}

-- Configuration
window_grouping.config = {
    -- Group indicator appearance
    indicator = {
        size = dpi(8),
        color = beautiful.bg_focus or "#535d6c",
        opacity = 0.7,
        position = "top_right", -- Where to show the group indicator
        margin = dpi(5),
    },
    
    -- Auto-grouping rules
    auto_group_rules = {
        -- Group Firefox windows together
        {
            match = {
                class = {"Firefox"}
            },
            group_name = "Web Browser"
        },
        -- Group terminals together
        {
            match = {
                class = {"URxvt", "XTerm", "kitty", "alacritty", "Gnome-terminal"}
            },
            group_name = "Terminals"
        },
        -- Group code editors together
        {
            match = {
                class = {"Code", "VSCodium", "Sublime_text", "Atom"}
            },
            group_name = "Code Editors"
        }
    },
    
    -- Notification settings
    notify_on_group_change = true,
    notification_timeout = 2
}

-- Internal state
window_grouping.groups = {} -- Table to store groups
window_grouping.group_indicators = {} -- Table to store group indicators

-- Helper function to get a color with alpha
local function get_color_with_alpha(color, alpha)
    if color:find("#") == 1 and #color == 7 then
        return color .. string.format("%02x", math.floor(alpha * 255))
    end
    return color
end

-- Logging function
local function log(message)
    if window_grouping.config.notify_on_group_change then
        naughty.notify({
            preset = naughty.config.presets.normal,
            title = "Window Groups",
            text = message,
            timeout = window_grouping.config.notification_timeout
        })
    end
end

-- Create a group indicator for a client
local function create_group_indicator(c, group_id)
    -- Remove any existing indicator
    if window_grouping.group_indicators[c.window] then
        window_grouping.group_indicators[c.window]:remove_from_screen()
        window_grouping.group_indicators[c.window] = nil
    end
    
    -- Get group color (use the stored color or the default)
    local group = window_grouping.groups[group_id]
    local color = group and group.color or window_grouping.config.indicator.color
    
    -- Create the indicator widget
    local indicator = wibox.widget {
        widget = wibox.container.background,
        bg = get_color_with_alpha(color, window_grouping.config.indicator.opacity),
        shape = gears.shape.circle,
        forced_width = window_grouping.config.indicator.size,
        forced_height = window_grouping.config.indicator.size
    }
    
    -- Create popup to display the indicator
    local popup = awful.popup {
        widget = indicator,
        ontop = true,
        bg = "#00000000", -- Transparent background
        visible = true,
        shape = gears.shape.circle,
        placement = function(d)
            local pos = window_grouping.config.indicator.position
            local margin = window_grouping.config.indicator.margin
            
            if pos == "top_right" then
                awful.placement.top_right(d, {
                    parent = c,
                    margins = { top = margin, right = margin }
                })
            elseif pos == "top_left" then
                awful.placement.top_left(d, {
                    parent = c,
                    margins = { top = margin, left = margin }
                })
            elseif pos == "bottom_right" then
                awful.placement.bottom_right(d, {
                    parent = c,
                    margins = { bottom = margin, right = margin }
                })
            elseif pos == "bottom_left" then
                awful.placement.bottom_left(d, {
                    parent = c,
                    margins = { bottom = margin, left = margin }
                })
            end
        end
    }
    
    -- Add tooltip showing group name
    if group and group.name then
        local tooltip = awful.tooltip {
            objects = { indicator },
            text = "Group: " .. group.name,
            mode = "outside",
            preferred_positions = { "top", "bottom", "right", "left" },
            margin_leftright = dpi(8),
            margin_topbottom = dpi(8)
        }
    end
    
    -- Store the indicator
    window_grouping.group_indicators[c.window] = popup
    
    -- When the client moves or resizes, move the indicator
    local update_indicator = function()
        if c.valid then
            popup.visible = true
            local placement_func = function(d)
                local pos = window_grouping.config.indicator.position
                local margin = window_grouping.config.indicator.margin
                
                if pos == "top_right" then
                    awful.placement.top_right(d, {
                        parent = c,
                        margins = { top = margin, right = margin }
                    })
                elseif pos == "top_left" then
                    awful.placement.top_left(d, {
                        parent = c,
                        margins = { top = margin, left = margin }
                    })
                elseif pos == "bottom_right" then
                    awful.placement.bottom_right(d, {
                        parent = c,
                        margins = { bottom = margin, right = margin }
                    })
                elseif pos == "bottom_left" then
                    awful.placement.bottom_left(d, {
                        parent = c,
                        margins = { bottom = margin, left = margin }
                    })
                end
            end
            
            placement_func(popup)
        else
            popup.visible = false
        end
    end
    
    c:connect_signal("property::geometry", update_indicator)
    c:connect_signal("property::minimized", function()
        popup.visible = not c.minimized
    end)
    
    -- Hide indicator when client is hidden or killed
    c:connect_signal("unmanage", function()
        popup.visible = false
        window_grouping.group_indicators[c.window] = nil
    end)
    
    return popup
end

-- Function to create a new group
function window_grouping.create_group(name, color)
    local group_id = tostring(os.time()) -- Use timestamp as unique ID
    
    window_grouping.groups[group_id] = {
        id = group_id,
        name = name or "Group " .. #window_grouping.groups + 1,
        color = color or window_grouping.config.indicator.color,
        clients = {},
        active = true -- Whether this group is active (receiving commands)
    }
    
    log("Created group: " .. window_grouping.groups[group_id].name)
    return group_id
end

-- Function to add a client to a group
function window_grouping.add_to_group(c, group_id)
    if not c or not c.valid then return false end
    
    local group = window_grouping.groups[group_id]
    if not group then return false end
    
    -- Check if already in this group
    if c.window_group_id == group_id then
        return true
    end
    
    -- Remove from previous group if any
    window_grouping.remove_from_group(c)
    
    -- Add to new group
    group.clients[c.window] = c
    c.window_group_id = group_id
    
    -- Create indicator
    create_group_indicator(c, group_id)
    
    log("Added " .. (c.name or "window") .. " to group " .. group.name)
    return true
end

-- Function to remove a client from its group
function window_grouping.remove_from_group(c)
    if not c or not c.valid or not c.window_group_id then return false end
    
    local group_id = c.window_group_id
    local group = window_grouping.groups[group_id]
    
    if not group then return false end
    
    -- Remove from group
    group.clients[c.window] = nil
    c.window_group_id = nil
    
    -- Remove indicator
    if window_grouping.group_indicators[c.window] then
        window_grouping.group_indicators[c.window]:remove_from_screen()
        window_grouping.group_indicators[c.window] = nil
    end
    
    log("Removed " .. (c.name or "window") .. " from group " .. group.name)
    
    -- If group is empty, consider removing it
    if next(group.clients) == nil then
        window_grouping.remove_group(group_id)
    end
    
    return true
end

-- Function to remove a group
function window_grouping.remove_group(group_id)
    local group = window_grouping.groups[group_id]
    if not group then return false end
    
    -- Remove all clients from the group
    for window, c in pairs(group.clients) do
        if c and c.valid then
            c.window_group_id = nil
            if window_grouping.group_indicators[window] then
                window_grouping.group_indicators[window]:remove_from_screen()
                window_grouping.group_indicators[window] = nil
            end
        end
    end
    
    -- Remove the group
    window_grouping.groups[group_id] = nil
    
    log("Removed group: " .. group.name)
    return true
end

-- Function to toggle a group's active state
function window_grouping.toggle_group_active(group_id)
    local group = window_grouping.groups[group_id]
    if not group then return false end
    
    group.active = not group.active
    
    -- Update indicators
    for window, c in pairs(group.clients) do
        if c and c.valid and window_grouping.group_indicators[window] then
            local indicator = window_grouping.group_indicators[window].widget
            indicator.bg = get_color_with_alpha(
                group.color, 
                group.active and window_grouping.config.indicator.opacity or 0.3
            )
        end
    end
    
    log("Group " .. group.name .. " is now " .. (group.active and "active" or "inactive"))
    return true
end

-- Function to execute a command on all clients in active groups
function window_grouping.execute_on_group(group_id, command)
    local group = window_grouping.groups[group_id]
    if not group or not group.active then return false end
    
    local count = 0
    for window, c in pairs(group.clients) do
        if c and c.valid then
            if command == "minimize" then
                c.minimized = true
            elseif command == "unminimize" then
                c.minimized = false
            elseif command == "maximize" then
                c.maximized = true
            elseif command == "unmaximize" then
                c.maximized = false
            elseif command == "close" then
                c:kill()
            elseif command == "focus" then
                c:emit_signal("request::activate", "group_command", {raise = true})
            elseif command == "move_to_tag" then
                -- Special case handled separately
            end
            count = count + 1
        end
    end
    
    if count > 0 then
        log("Executed " .. command .. " on " .. count .. " windows in group " .. group.name)
    end
    
    return true
end

-- Function to move all windows in a group to a tag
function window_grouping.move_group_to_tag(group_id, tag)
    local group = window_grouping.groups[group_id]
    if not group or not group.active or not tag then return false end
    
    local count = 0
    for window, c in pairs(group.clients) do
        if c and c.valid then
            c:move_to_tag(tag)
            count = count + 1
        end
    end
    
    if count > 0 then
        log("Moved " .. count .. " windows in group " .. group.name .. " to tag " .. tag.name)
    end
    
    return true
end

-- Function to check if a client should be auto-grouped
local function check_auto_group(c)
    if not c or not c.valid then return end
    
    for _, rule in ipairs(window_grouping.config.auto_group_rules) do
        local match = true
        
        -- Check class match
        if rule.match.class then
            local class_match = false
            for _, class in ipairs(rule.match.class) do
                if c.class and c.class:match(class) then
                    class_match = true
                    break
                end
            end
            match = match and class_match
        end
        
        -- Check name match
        if match and rule.match.name then
            local name_match = false
            for _, name in ipairs(rule.match.name) do
                if c.name and c.name:match(name) then
                    name_match = true
                    break
                end
            end
            match = match and name_match
        end
        
        if match then
            -- Find or create appropriate group
            local group_found = false
            for id, group in pairs(window_grouping.groups) do
                if group.name == rule.group_name then
                    window_grouping.add_to_group(c, id)
                    group_found = true
                    break
                end
            end
            
            if not group_found then
                local new_group_id = window_grouping.create_group(rule.group_name, rule.color)
                window_grouping.add_to_group(c, new_group_id)
            end
            
            break
        end
    end
end

-- Function to initialize window grouping
function window_grouping.init()
    -- Connect signals
    client.connect_signal("manage", function(c)
        -- Check for auto-grouping
        check_auto_group(c)
    end)
    
    client.connect_signal("unmanage", function(c)
        -- Remove from group if part of one
        window_grouping.remove_from_group(c)
    end)
    
    -- Initialize for existing clients
    for _, c in ipairs(client.get()) do
        check_auto_group(c)
    end
    
    log("Window Grouping initialized")
end

-- Function to configure the window grouping module
function window_grouping.configure(config)
    for k, v in pairs(config) do
        window_grouping.config[k] = v
    end
    log("Window Grouping configuration updated")
end

-- Key binding helper for group operations
function window_grouping.get_group_keybindings(mod, key_prefix)
    local mod = mod or {"Mod4", "Control"}
    local prefix = key_prefix or "g"
    
    return {
        awful.key(mod, prefix .. "n", function() 
            window_grouping.create_group() 
            if client.focus then
                window_grouping.add_to_group(client.focus, next(window_grouping.groups))
            end
        end, {description = "create new window group", group = "window groups"}),
        
        awful.key(mod, prefix .. "a", function()
            if client.focus and next(window_grouping.groups) then
                -- Show a menu to select which group to add to
                local items = {}
                for id, group in pairs(window_grouping.groups) do
                    table.insert(items, {
                        group.name, 
                        function() window_grouping.add_to_group(client.focus, id) end
                    })
                end
                
                awful.menu(items):show()
            end
        end, {description = "add window to group", group = "window groups"}),
        
        awful.key(mod, prefix .. "r", function()
            if client.focus then
                window_grouping.remove_from_group(client.focus)
            end
        end, {description = "remove window from group", group = "window groups"}),
        
        awful.key(mod, prefix .. "m", function()
            if client.focus and client.focus.window_group_id then
                -- Show all windows in this group
                local group = window_grouping.groups[client.focus.window_group_id]
                if group then
                    for _, c in pairs(group.clients) do
                        if c and c.valid then
                            c.minimized = false
                            c:emit_signal("request::activate", "group_command", {raise = true})
                        end
                    end
                end
            end
        end, {description = "show all windows in current group", group = "window groups"}),
        
        awful.key(mod, prefix .. "h", function()
            if client.focus and client.focus.window_group_id then
                -- Hide all other windows in this group
                local group = window_grouping.groups[client.focus.window_group_id]
                if group then
                    for _, c in pairs(group.clients) do
                        if c and c.valid and c ~= client.focus then
                            c.minimized = true
                        end
                    end
                end
            end
        end, {description = "hide other windows in current group", group = "window groups"}),
        
        awful.key(mod, prefix .. "c", function()
            if client.focus and client.focus.window_group_id then
                -- Close all windows in this group
                local group_id = client.focus.window_group_id
                window_grouping.execute_on_group(group_id, "close")
            end
        end, {description = "close all windows in current group", group = "window groups"}),
        
        awful.key(mod, prefix .. "t", function()
            if client.focus and client.focus.window_group_id then
                -- Toggle group active state
                window_grouping.toggle_group_active(client.focus.window_group_id)
            end
        end, {description = "toggle group active state", group = "window groups"})
    }
end

return window_grouping 