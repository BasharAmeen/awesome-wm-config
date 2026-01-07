--[[
    Window Rules Manager Module for AwesomeWM
    Logic for managing persistent window rules.
--]]

local awful = require("awful")
local naughty = require("naughty")
local gears = require("gears")

local window_rules_manager = {}

-- Path to the custom rules file
local rules_path = gears.filesystem.get_configuration_dir() .. "modules/rules/custom_rules.lua"

-- Cached custom rules
local custom_rules = {}

-- Load rules from file
function window_rules_manager.load_rules()
    local f = io.open(rules_path, "r")
    if f then
        f:close()
        -- Safely load the chunk
        local chunk, err = loadfile(rules_path)
        if chunk then
            -- Execute chunk to get the table
            -- Expected format: return { ... }
            local success, result = pcall(chunk)
            if success and type(result) == "table" then
                custom_rules = result
                window_rules_manager.apply_rules()
            else
                naughty.notify({ text = "Error executing rules file: " .. tostring(result), preset = naughty.config.presets.critical })
            end
        else
            naughty.notify({ text = "Error loading rules file: " .. tostring(err), preset = naughty.config.presets.critical })
        end
    end
end

-- Apply custom rules to awful.rules
function window_rules_manager.apply_rules()
    -- We assume the first rule in awful.rules.rules is the default catch-all,
    -- or at least that we should append our custom rules to the end.
    -- To avoid duplicates on reload, we might need a smarter strategy,
    -- but for now, let's append.
    -- A better way for hot-reloading: Remove old custom rules if we track them?
    -- For simplicity in this fix, we just append to the current running config.
    -- NOTE: In a full restart, this runs once. In hot-reload, this might duplicate if not careful.
    -- But usually `awful.rules.rules` is reset on config reload.
    
    for _, rule in ipairs(custom_rules) do
        table.insert(awful.rules.rules, rule)
    end
end

-- Get current custom rules
function window_rules_manager.get_custom_rules()
    return custom_rules
end

-- Add a new rule
function window_rules_manager.add_rule(new_rule)
    table.insert(custom_rules, new_rule)
    window_rules_manager.save_rules()
    -- Re-apply immediately (append/update)
    table.insert(awful.rules.rules, new_rule)
    naughty.notify({ text = "Rule added and saved." })
end

-- Remove a rule by index
function window_rules_manager.remove_rule(index)
    if custom_rules[index] then
        table.remove(custom_rules, index)
        window_rules_manager.save_rules()
        naughty.notify({ text = "Rule removed. Restart AwesomeWM to fully clear effect." })
        -- Note: Removing from running awful.rules is harder without tracking IDs.
        -- We notify user to restart for full effect.
    end
end

-- Serialize table to string
local function serialize_table(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            local key_str
            if type(k) == "number" then
                key_str = nil -- Implicit index
            elseif type(k) == "string" and k:match("^[%a_][%w_]*$") then
                key_str = k
            else
                key_str = "[" .. string.format("%q", k) .. "]"
            end

            tmp = tmp .. serialize_table(v, key_str, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. '"[inserializeable datatype:' .. type(val) .. ']"'
    end

    return tmp
end

-- Save rules to file
function window_rules_manager.save_rules()
    local file = io.open(rules_path, "w")
    if file then
        file:write("return {\n")
        for _, rule in ipairs(custom_rules) do
             -- Use a simplified serializer or custom one for clean output
             -- We need to serialize the rule table
             file:write(serialize_table(rule, nil, false, 4) .. ",\n")
        end
        file:write("}\n")
        file:close()
    else
        naughty.notify({ text = "Failed to write rules to " .. rules_path, preset = naughty.config.presets.critical })
    end
end

-- Export rules to a user-specified location
function window_rules_manager.export_rules()
    local export_path = os.getenv("HOME") .. "/awesome_rules_backup.lua"
    local file = io.open(export_path, "w")
    if file then
        file:write("-- AwesomeWM Custom Rules Backup\n")
        file:write("-- Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n")
        file:write("return {\n")
        for _, rule in ipairs(custom_rules) do
            file:write(serialize_table(rule, nil, false, 4) .. ",\n")
        end
        file:write("}\n")
        file:close()
        naughty.notify({ text = "Rules exported to " .. export_path })
    else
        naughty.notify({ text = "Failed to export rules", preset = naughty.config.presets.critical })
    end
end

-- Import rules from a backup file
function window_rules_manager.import_rules()
    local import_path = os.getenv("HOME") .. "/awesome_rules_backup.lua"
    local f = io.open(import_path, "r")
    if f then
        f:close()
        local chunk, err = loadfile(import_path)
        if chunk then
            local success, result = pcall(chunk)
            if success and type(result) == "table" then
                -- Merge imported rules with existing
                for _, rule in ipairs(result) do
                    table.insert(custom_rules, rule)
                end
                window_rules_manager.save_rules()
                window_rules_manager.apply_rules()
                naughty.notify({ text = "Imported " .. #result .. " rules from " .. import_path })
            else
                naughty.notify({ text = "Error parsing rules file", preset = naughty.config.presets.critical })
            end
        else
            naughty.notify({ text = "Error loading rules file: " .. tostring(err), preset = naughty.config.presets.critical })
        end
    else
        naughty.notify({ text = "No backup file found at " .. import_path, preset = naughty.config.presets.critical })
    end
end

return window_rules_manager