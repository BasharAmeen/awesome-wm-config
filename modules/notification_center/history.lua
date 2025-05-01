---------------------------------------------------------
-- Notification Center - History Module
-- Stores and manages notification history
---------------------------------------------------------

local gears = require("gears")
local naughty = require("naughty")
local beautiful = require("beautiful")
local lgi = require("lgi")
local GLib = lgi.GLib

-- Define the history module
local history = {}
history.notifications = {}
history.unread_count = 0
history.signals = {}

-- Initialize signals
function history.connect_signal(name, callback)
    history.signals[name] = history.signals[name] or {}
    table.insert(history.signals[name], callback)
end

function history.emit_signal(name, ...)
    if history.signals[name] then
        for _, callback in ipairs(history.signals[name]) do
            callback(...)
        end
    end
end

-- Initialize the module
function history.init(config)
    history.config = config
    history.notifications = {}
    history.by_app = {}
    history.unread_count = 0
    
    -- Save notifications to file on awesome exit
    awesome.connect_signal("exit", function()
        history.save_to_file()
    end)
    
    -- Load saved notifications on init
    history.load_from_file()
    
    return history
end

-- Add a notification to history
function history.add_notification(notification)
    -- Create a unique ID if not present
    notification.id = notification.id or os.time() .. "_" .. math.random(1000, 9999)
    
    -- Add timestamp
    notification.timestamp = os.time()
    
    -- Add read status
    notification.read = false
    
    -- Get or create application group
    local app_name = notification.app_name or "unknown"
    history.by_app[app_name] = history.by_app[app_name] or {
        notifications = {},
        name = app_name,
        icon = notification.icon or nil,
        count = 0
    }
    
    -- Add to general notifications list
    table.insert(history.notifications, 1, notification)
    
    -- Add to app-specific list
    table.insert(history.by_app[app_name].notifications, 1, notification)
    history.by_app[app_name].count = history.by_app[app_name].count + 1
    
    -- Update unread count
    history.unread_count = history.unread_count + 1
    
    -- Limit the number of stored notifications
    if #history.notifications > history.config.max_notifications then
        -- Get the last notification to remove
        local to_remove = table.remove(history.notifications)
        
        -- Remove from app-specific list
        local app = history.by_app[to_remove.app_name or "unknown"]
        for i, notif in ipairs(app.notifications) do
            if notif.id == to_remove.id then
                table.remove(app.notifications, i)
                app.count = app.count - 1
                break
            end
        end
        
        -- Update unread count if needed
        if not to_remove.read then
            history.unread_count = history.unread_count - 1
        end
    end
    
    -- Emit signals
    history.emit_signal("notification_added", notification)
    history.emit_signal("count_updated", history.unread_count)
    history.emit_signal("history_updated", history.notifications)
    
    return notification
end

-- Mark a notification as read
function history.mark_as_read(notification)
    -- Find in general list
    for _, notif in ipairs(history.notifications) do
        if notif.id == notification.id and not notif.read then
            notif.read = true
            history.unread_count = history.unread_count - 1
            
            -- Update in app-specific list
            local app_name = notif.app_name or "unknown"
            if history.by_app[app_name] then
                for _, app_notif in ipairs(history.by_app[app_name].notifications) do
                    if app_notif.id == notification.id then
                        app_notif.read = true
                        break
                    end
                end
            end
            
            -- Emit signals
            history.emit_signal("notification_read", notification)
            history.emit_signal("count_updated", history.unread_count)
            history.emit_signal("history_updated", history.notifications)
            
            break
        end
    end
end

-- Mark all notifications as read
function history.clear_all()
    for _, notif in ipairs(history.notifications) do
        notif.read = true
    end
    
    history.unread_count = 0
    
    -- Emit signals
    history.emit_signal("count_updated", history.unread_count)
    history.emit_signal("history_updated", history.notifications)
    history.emit_signal("cleared")
end

-- Clear notifications for a specific app
function history.clear_app(app_name)
    if not history.by_app[app_name] then return end
    
    -- Mark all as read
    for _, notif in ipairs(history.by_app[app_name].notifications) do
        if not notif.read then
            notif.read = true
            history.unread_count = history.unread_count - 1
        end
    end
    
    -- Emit signals
    history.emit_signal("count_updated", history.unread_count)
    history.emit_signal("history_updated", history.notifications)
    history.emit_signal("app_cleared", app_name)
end

-- Remove a specific notification
function history.remove_notification(id)
    -- Find and remove from general list
    for i, notif in ipairs(history.notifications) do
        if notif.id == id then
            local notification = table.remove(history.notifications, i)
            
            -- Update unread count if needed
            if not notification.read then
                history.unread_count = history.unread_count - 1
            end
            
            -- Remove from app-specific list
            local app_name = notification.app_name or "unknown"
            if history.by_app[app_name] then
                for j, app_notif in ipairs(history.by_app[app_name].notifications) do
                    if app_notif.id == id then
                        table.remove(history.by_app[app_name].notifications, j)
                        history.by_app[app_name].count = history.by_app[app_name].count - 1
                        break
                    end
                end
            end
            
            -- Emit signals
            history.emit_signal("notification_removed", notification)
            history.emit_signal("count_updated", history.unread_count)
            history.emit_signal("history_updated", history.notifications)
            
            break
        end
    end
end

-- Get notifications grouped by application
function history.get_by_app()
    local result = {}
    
    -- Convert hash table to array for easier UI rendering
    for app_name, app_data in pairs(history.by_app) do
        if #app_data.notifications > 0 then
            table.insert(result, app_data)
        end
    end
    
    -- Sort by most recent notification
    table.sort(result, function(a, b)
        if #a.notifications == 0 then return false end
        if #b.notifications == 0 then return true end
        
        return a.notifications[1].timestamp > b.notifications[1].timestamp
    end)
    
    return result
end

-- Get all notifications as flat list
function history.get_all()
    return history.notifications
end

-- Get unread count
function history.get_unread_count()
    return history.unread_count
end

-- Save notifications to file
function history.save_to_file()
    -- Create a simplified version of notifications to save
    local to_save = {}
    
    for _, notif in ipairs(history.notifications) do
        -- Don't save too old notifications
        local age = os.time() - notif.timestamp
        if age < 86400 then -- Only keep notifications from the last 24 hours
            table.insert(to_save, {
                id = notif.id,
                title = notif.title,
                message = notif.message,
                app_name = notif.app_name,
                icon = notif.icon,
                timestamp = notif.timestamp,
                read = notif.read
            })
        end
    end
    
    -- Save to file
    local config_dir = GLib.get_user_config_dir()
    local file_path = config_dir .. "/awesome/notification_history.json"
    
    -- Serialize to JSON
    local json = gears.json.encode(to_save)
    
    -- Write to file
    local file = io.open(file_path, "w")
    if file then
        file:write(json)
        file:close()
    else
        naughty.notify({
            title = "Notification Center",
            text = "Failed to save notification history",
            preset = naughty.config.presets.critical
        })
    end
end

-- Load notifications from file
function history.load_from_file()
    local config_dir = GLib.get_user_config_dir()
    local file_path = config_dir .. "/awesome/notification_history.json"
    
    -- Try to open file
    local file = io.open(file_path, "r")
    if not file then
        return
    end
    
    -- Read content
    local content = file:read("*all")
    file:close()
    
    if not content or content == "" then
        return
    end
    
    -- Parse JSON
    local success, saved_notifications = pcall(gears.json.decode, content)
    if not success or not saved_notifications then
        naughty.notify({
            title = "Notification Center",
            text = "Failed to load notification history",
            preset = naughty.config.presets.critical
        })
        return
    end
    
    -- Process saved notifications
    for _, notif in ipairs(saved_notifications) do
        history.add_notification(notif)
    end
end

-- Filter notifications by search term
function history.filter(term)
    if not term or term == "" then
        return history.notifications
    end
    
    local term_lower = string.lower(term)
    local results = {}
    
    for _, notif in ipairs(history.notifications) do
        local title = notif.title and string.lower(notif.title) or ""
        local message = notif.message and string.lower(notif.message) or ""
        local app_name = notif.app_name and string.lower(notif.app_name) or ""
        
        if string.find(title, term_lower) or string.find(message, term_lower) or string.find(app_name, term_lower) then
            table.insert(results, notif)
        end
    end
    
    return results
end

return history 