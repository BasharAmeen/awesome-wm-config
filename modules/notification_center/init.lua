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

-- Helper function to save notification to history
local function save_notification(args)
    -- Use a timer to avoid blocking main thread with file I/O
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
        return false
    end)
end

-- Hook into notification system
if naughty.connect_signal then
    -- Modern AwesomeWM (preferred): Hook into the signal
    naughty.connect_signal("added", function(n)
        save_notification({
            app_name = n.app_name or "System",
            title = n.title or "",
            text = n.message or n.text or "",
            icon = n.icon,
            urgency = n.urgency or "normal",
        })
    end)
else
    -- Fallback for older versions: Override naughty.notify
    local original_notify = naughty.notify
    naughty.notify = function(args)
        save_notification(args)
        return original_notify(args)
    end
end

-- Open rofi notification history viewer
function notification_center.show()
    local script_path = gears.filesystem.get_configuration_dir() .. "modules/notification_center/rofi_viewer.sh"
    local history_path = history.FILE_PATH
    
    -- Ensure script is executable (just in case)
    awful.spawn.with_shell("chmod +x " .. script_path)
    
    awful.spawn.with_shell(script_path .. " " .. history_path)
end

-- Alias for toggle
function notification_center.toggle()
    notification_center.show()
end

return notification_center
