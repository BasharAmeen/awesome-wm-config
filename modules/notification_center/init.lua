---------------------------------------------------------
-- Notification Center for AwesomeWM
-- A centralized notification history panel
---------------------------------------------------------

local awful = require("awful")
local naughty = require("naughty")
local beautiful = require("beautiful")
local wibox = require("wibox")
local gears = require("gears")
local dpi = require("beautiful.xresources").apply_dpi

local panel = require("modules.notification_center.panel")
local history = require("modules.notification_center.history")
local actions = require("modules.notification_center.actions")

local notification_center = {}

-- Initialize notification center
function notification_center.init(args)
    args = args or {}
    
    -- Set up default config
    notification_center.config = {
        width = args.width or dpi(400),
        max_notifications = args.max_notifications or 100,
        timeout = args.timeout or 5,
        position = args.position or "right",
        show_on_startup = args.show_on_startup or false,
        keybinding = args.keybinding or { modkey = "Mod4", key = "n" }
    }
    
    -- Initialize components
    history.init(notification_center.config)
    panel.init(notification_center.config)
    actions.init(notification_center.config)
    
    -- Setup notification interception
    notification_center.setup_interception()
    
    -- Setup keybinding
    notification_center.setup_keybinding()
    
    -- Create panel toggle button for wibar (optional)
    notification_center.create_button()
    
    -- Initial state
    if notification_center.config.show_on_startup then
        panel.show()
    else
        panel.hide()
    end
    
    return notification_center
end

-- Intercept notifications to store them
function notification_center.setup_interception()
    -- Store original notify function
    local original_notify = naughty.notify
    
    -- Override naughty.notify to intercept notifications
    naughty.notify = function(args)
        -- Process notification and add to history
        history.add_notification(args)
        
        -- Pass to original function
        return original_notify(args)
    end
    
    -- Intercept notification destruction
    naughty.connect_signal("destroyed", function(n, reason)
        if reason == naughty.notificationClosedReason.dismissed_by_user then
            history.mark_as_read(n)
        end
    end)
end

-- Setup keyboard shortcut
function notification_center.setup_keybinding()
    local config = notification_center.config
    
    awful.keyboard.append_global_keybindings({
        awful.key(
            { config.keybinding.modkey }, config.keybinding.key,
            function()
                panel.toggle()
            end,
            { description = "toggle notification center", group = "awesome" }
        )
    })
end

-- Create a button for the wibar
function notification_center.create_button()
    notification_center.widget = wibox.widget {
        {
            {
                id = "icon",
                text = "",
                font = "FontAwesome 11",
                widget = wibox.widget.textbox,
            },
            id = "margin_role",
            left = dpi(4),
            right = dpi(4),
            widget = wibox.container.margin
        },
        bg = beautiful.bg_normal,
        widget = wibox.container.background
    }
    
    -- Update badge count
    history.connect_signal("count_updated", function(count)
        local icon_widget = notification_center.widget:get_children_by_id("icon")[1]
        
        if count > 0 then
            icon_widget.markup = "<span foreground='" .. beautiful.fg_urgent .. "'> " .. count .. "</span>"
        else
            icon_widget.markup = "<span> 0</span>"
        end
    end)
    
    -- Connect click
    notification_center.widget:buttons(
        gears.table.join(
            awful.button({}, 1, function()
                panel.toggle()
            end)
        )
    )
    
    return notification_center.widget
end

-- Toggle notification center
function notification_center.toggle()
    panel.toggle()
end

-- Show notification center
function notification_center.show()
    panel.show()
end

-- Hide notification center
function notification_center.hide()
    panel.hide()
end

-- Mark all notifications as read
function notification_center.clear_all()
    history.clear_all()
end

return notification_center 