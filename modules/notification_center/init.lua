-- notification_center/init.lua
-- Simple module: hooks into naughty to capture and store notifications
-- Uses rofi script for viewing

local naughty = require("naughty")
local gears = require("gears")
local awful = require("awful")

local notification_center = {}

-- Load history module
local history = require("modules.notification_center.history")
notification_center.history = history

-- Track if we're currently processing to avoid recursion
local is_processing = false

-- Helper function to save notification to history
local function save_notification(args)
    if is_processing then return end
    is_processing = true
    
    -- Use a timer to avoid blocking
    gears.timer.start_new(0.1, function()
        pcall(function()
            history.add({
                app_name = args.app_name or "System",
                title = args.title or "",
                message = args.text or args.message or "",
                icon = args.icon,
                urgency = args.urgency or "normal",
            })
        end)
        is_processing = false
        return false
    end)
end

-- Hook into naughty.notify (catches all notification calls, even when suspended)
local original_notify = naughty.notify
naughty.notify = function(args)
    -- ALWAYS save to history first, before checking suspension
    save_notification(args)
    
    -- Call original notify (which handles suspension internally)
    return original_notify(args)
end

-- Also hook into the newer notification API for external D-Bus notifications
if naughty.connect_signal then
    naughty.connect_signal("added", function(n)
        save_notification({
            app_name = n.app_name or "System",
            title = n.title or "",
            text = n.message or n.text or "",
            icon = n.icon,
            urgency = n.urgency or "normal",
        })
    end)
end

-- Open rofi notification history viewer
function notification_center.show()
    awful.spawn.with_shell("~/.config/awesome/scripts/notification_history.sh")
end

-- Alias for toggle
function notification_center.toggle()
    notification_center.show()
end

return notification_center
