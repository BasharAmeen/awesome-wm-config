-- notification_center/history.lua
-- Persistent notification history with JSON storage

local gears = require("gears")
local gfs = require("gears.filesystem")
local json = require("modules.notification_center.json")

local history = {}

-- Configuration
local DATA_DIR = gfs.get_configuration_dir() .. "data/notifications/"
local HISTORY_FILE = DATA_DIR .. "history.json"
local ICONS_DIR = DATA_DIR .. "icons/"
local MAX_HISTORY = 500  -- Maximum notifications to keep

-- Ensure directories exist
local function ensure_dirs()
    os.execute("mkdir -p " .. ICONS_DIR)
end

-- Generate unique ID
local function generate_id()
    return os.date("%Y%m%d%H%M%S") .. "_" .. math.random(1000, 9999)
end

-- Load history from disk
function history.load()
    ensure_dirs()
    local file = io.open(HISTORY_FILE, "r")
    if not file then
        return {}
    end
    
    local content = file:read("*all")
    file:close()
    
    if content == "" or content == nil then
        return {}
    end
    
    local ok, data = pcall(json.decode, content)
    if ok and type(data) == "table" then
        return data
    end
    return {}
end

-- Save history to disk
function history.save_all(data)
    ensure_dirs()
    
    -- Limit history size
    while #data > MAX_HISTORY do
        -- Remove oldest entry and its icon
        local oldest = table.remove(data, 1)
        if oldest.icon_path and oldest.icon_path ~= "" then
            os.remove(DATA_DIR .. oldest.icon_path)
        end
    end
    
    local file = io.open(HISTORY_FILE, "w")
    if file then
        local ok, encoded = pcall(json.encode, data)
        if ok then
            file:write(encoded)
        end
        file:close()
    end
end

-- Save a notification icon to disk
function history.save_icon(icon, id)
    if not icon or icon == "" then
        return nil
    end
    
    -- If icon is a path, copy it
    if type(icon) == "string" and gfs.file_readable(icon) then
        local icon_name = "icons/" .. id .. ".png"
        local dest_path = DATA_DIR .. icon_name
        os.execute("cp " .. icon .. " " .. dest_path .. " 2>/dev/null")
        if gfs.file_readable(dest_path) then
            return icon_name
        end
    end
    
    return nil
end

-- Add a new notification to history
function history.add(notification)
    local data = history.load()
    local id = generate_id()
    
    -- Save icon if present
    local icon_path = history.save_icon(notification.icon, id)
    
    local entry = {
        id = id,
        timestamp = os.date("%Y-%m-%dT%H:%M:%S"),
        app_name = notification.app_name or "Unknown",
        title = notification.title or "",
        text = notification.message or notification.text or "",
        urgency = notification.urgency or "normal",
        icon_path = icon_path,
    }
    
    table.insert(data, entry)
    history.save_all(data)
    
    return entry
end

-- Search notifications by text
function history.search(query)
    local data = history.load()
    local results = {}
    local query_lower = string.lower(query or "")
    
    for _, n in ipairs(data) do
        local title_lower = string.lower(n.title or "")
        local text_lower = string.lower(n.text or "")
        local app_lower = string.lower(n.app_name or "")
        
        if string.find(title_lower, query_lower, 1, true) or
           string.find(text_lower, query_lower, 1, true) or
           string.find(app_lower, query_lower, 1, true) then
            table.insert(results, n)
        end
    end
    
    return results
end

-- Filter by date range (days_ago = how many days back to include)
function history.filter_by_days(days_ago)
    local data = history.load()
    local results = {}
    local cutoff = os.time() - (days_ago * 24 * 60 * 60)
    
    for _, n in ipairs(data) do
        -- Parse timestamp
        local y, m, d, h, min, s = n.timestamp:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
        if y then
            local ts = os.time({year=y, month=m, day=d, hour=h, min=min, sec=s})
            if ts >= cutoff then
                table.insert(results, n)
            end
        end
    end
    
    return results
end

-- Filter by app name
function history.filter_by_app(app_name)
    local data = history.load()
    local results = {}
    
    for _, n in ipairs(data) do
        if n.app_name == app_name then
            table.insert(results, n)
        end
    end
    
    return results
end

-- Get unique app names
function history.get_apps()
    local data = history.load()
    local apps = {}
    local seen = {}
    
    for _, n in ipairs(data) do
        if n.app_name and not seen[n.app_name] then
            seen[n.app_name] = true
            table.insert(apps, n.app_name)
        end
    end
    
    table.sort(apps)
    return apps
end

-- Delete a notification by ID
function history.delete(id)
    local data = history.load()
    
    for i, n in ipairs(data) do
        if n.id == id then
            -- Remove icon file
            if n.icon_path and n.icon_path ~= "" then
                os.remove(DATA_DIR .. n.icon_path)
            end
            table.remove(data, i)
            history.save_all(data)
            return true
        end
    end
    
    return false
end

-- Clear all history
function history.clear()
    -- Remove all icons
    os.execute("rm -rf " .. ICONS_DIR .. "*")
    
    -- Clear the JSON file
    local file = io.open(HISTORY_FILE, "w")
    if file then
        file:write("[]")
        file:close()
    end
end

-- Get recent notifications (limited count)
function history.get_recent(count)
    local data = history.load()
    local results = {}
    local start_idx = math.max(1, #data - (count or 50) + 1)
    
    for i = #data, start_idx, -1 do
        table.insert(results, data[i])
    end
    
    return results
end

return history
