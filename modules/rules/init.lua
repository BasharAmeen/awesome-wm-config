--[[
    Rules Module for AwesomeWM
    Initializes window rules related modules and functionality
--]]

local window_rules_manager = require("modules.rules.window_rules_manager")

-- Try to import saved rules on startup
local function init()
    -- Add a small delay to ensure all dependencies are loaded
    local gtimer = require("gears.timer")
    local naughty = require("naughty")
    
    gtimer.start_new(2, function()
        local success, err = pcall(function()
            -- Check if custom rules file exists
            local file_path = os.getenv("HOME") .. "/.config/awesome/modules/rules/custom_rules.lua"
            local file = io.open(file_path, "r")
            if file then
                file:close()
                -- Import the rules
                window_rules_manager.import_rules()
            end
        end)
        
        if not success then
            naughty.notify({
                title = "Window Rules Manager",
                text = "Error during initialization: " .. tostring(err),
                timeout = 5
            })
        end
        
        return false -- Don't repeat
    end)
end

-- Initialize the module
init()

local rules = {
    window_rules_manager = window_rules_manager
}

return rules 