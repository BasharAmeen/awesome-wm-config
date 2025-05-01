---------------------------------------------------------
-- Notification Center - Actions Module
-- Handles notification actions
---------------------------------------------------------

local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")

local actions = {}

-- Initialize the module
function actions.init(config)
    actions.config = config
    return actions
end

-- Execute a notification action
function actions.execute(notification, action_key)
    if not notification or not notification.actions then
        return false
    end
    
    -- Find the action by key
    for _, action in ipairs(notification.actions) do
        if action.key == action_key then
            -- Execute the action callback if it exists
            if type(action.callback) == "function" then
                action.callback(notification)
                return true
            end
            
            -- Try to execute default action based on key if no callback exists
            return actions.execute_default_action(notification, action)
        end
    end
    
    return false
end

-- Execute default actions based on common patterns
function actions.execute_default_action(notification, action)
    -- If the action has a name indicating a URL, try to open it
    local action_name = action.name and string.lower(action.name) or ""
    
    if string.find(action_name, "open") or 
       string.find(action_name, "view") or 
       string.find(action_name, "show") then
        
        -- Check if there's a URL in the notification
        local url = actions.extract_url(notification)
        if url then
            awful.spawn("xdg-open " .. url)
            return true
        end
    end
    
    -- Try to invoke the application that sent the notification
    if notification.app_name then
        awful.spawn(string.lower(notification.app_name))
        return true
    end
    
    return false
end

-- Extract URL from notification text
function actions.extract_url(notification)
    local text = notification.message or notification.title or ""
    
    -- Look for URLs in the text
    local url = string.match(text, "https?://[%w-_%.%?%.:/%+=&]+")
    
    return url
end

-- Create default action for a notification
function actions.create_default_action(notification)
    local default_action = {
        key = "default",
        name = "Open"
    }
    
    -- Determine the appropriate action based on the notification content
    local app_name = string.lower(notification.app_name or "")
    
    if app_name == "firefox" or app_name == "chromium" or app_name == "brave" then
        default_action.name = "Open in Browser"
    elseif app_name == "thunderbird" or app_name == "evolution" or string.find(app_name, "mail") then
        default_action.name = "Open Message"
    elseif app_name == "spotify" or app_name == "rhythmbox" or app_name == "mpd" then
        default_action.name = "Open Player"
    else
        local url = actions.extract_url(notification)
        if url then
            default_action.name = "Open Link"
            default_action.callback = function()
                awful.spawn("xdg-open " .. url)
            end
        else
            default_action.name = "Open App"
            default_action.callback = function()
                awful.spawn(app_name)
            end
        end
    end
    
    return default_action
end

-- Handle dismissing a notification
function actions.dismiss(notification)
    if not notification then return end
    
    if notification.box then
        notification.box.visible = false
    end
    
    -- If this is a real naughty notification object, try to destroy it
    if notification.destroy and type(notification.destroy) == "function" then
        notification:destroy(naughty.notificationClosedReason.dismissed_by_user)
    end
end

-- Get actions for a notification
function actions.get_actions(notification)
    local result = {}
    
    if notification.actions then
        -- Use the existing actions
        for _, action in ipairs(notification.actions) do
            table.insert(result, action)
        end
    else
        -- Create a default action
        local default_action = actions.create_default_action(notification)
        table.insert(result, default_action)
    end
    
    -- Always add dismiss action 
    table.insert(result, {
        key = "dismiss",
        name = "Dismiss"
    })
    
    return result
end

-- Log all notifications actions (for debugging)
function actions.log_action(notification, action)
    if not notification or not action then return end
    
    naughty.notify({
        title = "Action Executed",
        text = string.format("Action '%s' for notification from %s", 
                 action.name, notification.app_name or "unknown"),
        timeout = 5
    })
end

return actions 