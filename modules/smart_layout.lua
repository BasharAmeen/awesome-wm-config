local awful = require("awful")
local naughty = require("naughty")
local gears = require("gears")
local beautiful = require("beautiful")

-- Smart Layout Switching module
local smart_layout = {}

-- Configuration
smart_layout.config = {
    -- Default layout for each number of clients
    default_by_count = {
        [1] = awful.layout.suit.floating,        -- Single window: floating
        [2] = awful.layout.suit.tile,            -- Two windows: tile
        [3] = awful.layout.suit.tile,            -- Three windows: tile
        [4] = awful.layout.suit.fair,            -- Four windows: fair
        [5] = awful.layout.suit.fair,            -- Five windows: fair
        default = awful.layout.suit.spiral       -- More than 5: spiral
    },
    
    -- Override layouts for specific applications
    app_specific_layouts = {
        -- Terminal-heavy workspaces get a tiled layout
        ["terminal"] = {
            trigger_count = 2, -- If 2+ terminals are present
            layout = awful.layout.suit.tile
        },
        
        -- Firefox, Chrome, or other browsers
        ["browser"] = {
            trigger_count = 1, -- If any browser is present
            layout = awful.layout.suit.max -- Maximize browser windows
        },
        
        -- For image or document viewing
        ["viewer"] = {
            trigger_count = 1,
            layout = awful.layout.suit.fair
        },
        
        -- For coding with multiple windows
        ["editor"] = {
            trigger_count = 2,
            layout = awful.layout.suit.tile
        }
    },
    
    -- Application class to type mapping
    app_class_mapping = {
        -- Terminals
        ["URxvt"] = "terminal",
        ["XTerm"] = "terminal",
        ["kitty"] = "terminal",
        ["alacritty"] = "terminal",
        ["Gnome-terminal"] = "terminal",
        ["Termite"] = "terminal",
        
        -- Browsers
        ["Firefox"] = "browser",
        ["Google-chrome"] = "browser",
        ["Chromium"] = "browser",
        ["Brave-browser"] = "browser",
        ["Opera"] = "browser",
        
        -- Viewers
        ["Evince"] = "viewer",
        ["Zathura"] = "viewer",
        ["Sxiv"] = "viewer",
        ["Feh"] = "viewer",
        ["Ristretto"] = "viewer",
        ["Eog"] = "viewer",
        ["Gimp"] = "viewer",
        
        -- Editors/IDEs
        ["code"] = "editor",
        ["Code"] = "editor",
        ["VSCodium"] = "editor",
        ["Atom"] = "editor",
        ["Sublime_text"] = "editor",
        ["Gedit"] = "editor",
        ["Emacs"] = "editor"
    },
    
    -- Specific tag preferences - tag name to layout
    tag_specific_layouts = {
        ["1"] = awful.layout.suit.spiral,    -- First tag: spiral
        ["2"] = awful.layout.suit.fair,      -- Second tag: fair
        ["web"] = awful.layout.suit.max,     -- Web tag: maximize
        ["dev"] = awful.layout.suit.tile,    -- Dev tag: tile
        ["media"] = awful.layout.suit.max    -- Media tag: maximize
    },
    
    -- Notification settings
    notify_on_change = true,
    notification_timeout = 2,
    
    -- Throttling to prevent rapid layout changes
    throttle_seconds = 1
}

-- Internal state variables
local last_layout_change = 0
local current_layout = nil

-- Logging function
local function log(message)
    naughty.notify({
        preset = naughty.config.presets.normal,
        title = "Smart Layout",
        text = message,
        timeout = smart_layout.config.notification_timeout
    })
end

-- Get the best layout for a given tag based on client count and types
local function get_best_layout_for_tag(tag)
    -- Tag-specific layout overrides have highest priority
    if smart_layout.config.tag_specific_layouts[tag.name] then
        return smart_layout.config.tag_specific_layouts[tag.name]
    end
    
    -- Count total clients and clients by type
    local clients = tag:clients()
    local client_count = #clients
    local client_types = {}
    
    for _, client in ipairs(clients) do
        local class = client.class or ""
        local type = smart_layout.config.app_class_mapping[class] or "unknown"
        
        client_types[type] = (client_types[type] or 0) + 1
    end
    
    -- Check for app-specific layout rules
    for app_type, rule in pairs(smart_layout.config.app_specific_layouts) do
        if client_types[app_type] and client_types[app_type] >= rule.trigger_count then
            return rule.layout
        end
    end
    
    -- Fall back to client count-based layout
    return smart_layout.config.default_by_count[client_count] 
           or smart_layout.config.default_by_count.default
end

-- Function to apply the best layout to a tag
local function apply_smart_layout(tag)
    -- Throttling to prevent rapid changes
    local now = os.time()
    if now - last_layout_change < smart_layout.config.throttle_seconds then
        return
    end
    
    -- Get the best layout for this tag
    local best_layout = get_best_layout_for_tag(tag)
    
    -- If the current layout is different from the best layout
    if best_layout ~= awful.layout.get(tag.screen) then
        -- Store previous layout
        local prev_layout_name = awful.layout.getname(awful.layout.get(tag.screen))
        
        -- Apply the new layout
        awful.layout.set(best_layout, tag)
        
        -- Update last change time
        last_layout_change = now
        
        -- Notify about the change if enabled
        if smart_layout.config.notify_on_change then
            log("Layout changed to " .. awful.layout.getname(best_layout) .. 
                " from " .. prev_layout_name)
        end
    end
end

-- Function to process client events
local function handle_client_event(c)
    local tag = c.first_tag
    if tag then
        -- Apply smart layout to the tag
        apply_smart_layout(tag)
    end
end

-- Function to initialize the smart layout module
function smart_layout.init()
    -- Connect to signals that might warrant a layout change
    client.connect_signal("manage", handle_client_event)
    client.connect_signal("unmanage", handle_client_event)
    client.connect_signal("tagged", handle_client_event)
    client.connect_signal("untagged", handle_client_event)
    client.connect_signal("property::minimized", handle_client_event)
    client.connect_signal("property::fullscreen", handle_client_event)
    
    -- Apply smart layout when switching tags
    tag.connect_signal("property::selected", function(t)
        if t.selected then
            apply_smart_layout(t)
        end
    end)
    
    -- Initial application of layouts to all tags
    for s in screen do
        for _, t in ipairs(s.tags) do
            if t.selected then
                apply_smart_layout(t)
            end
        end
    end
    
    -- Log initialization
    log("Smart Layout initialized")
end

-- Function to manually trigger layout evaluation
function smart_layout.evaluate()
    local tag = awful.screen.focused().selected_tag
    if tag then
        apply_smart_layout(tag)
    end
end

-- Function to disable smart layout
function smart_layout.disable()
    -- Disconnect signals
    client.disconnect_signal("manage", handle_client_event)
    client.disconnect_signal("unmanage", handle_client_event)
    client.disconnect_signal("tagged", handle_client_event)
    client.disconnect_signal("untagged", handle_client_event)
    client.disconnect_signal("property::minimized", handle_client_event)
    client.disconnect_signal("property::fullscreen", handle_client_event)
    
    tag.disconnect_signal("property::selected", handle_client_event)
    
    log("Smart Layout disabled")
end

-- Add additional configuration function
function smart_layout.configure(config)
    for k, v in pairs(config) do
        smart_layout.config[k] = v
    end
    log("Smart Layout configuration updated")
end

return smart_layout 