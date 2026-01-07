--[[
    Rules Module for AwesomeWM
    Initializes window rules related modules and functionality
--]]

local window_rules_manager = require("modules.rules.window_rules_manager")
local rofi_manager = require("modules.rules.rofi_manager")
local gears = require("gears")

-- Initialize the module
local function init()
    -- Load saved rules on startup
    -- Use a timer to ensure other Awesome components are ready if needed,
    -- though usually rules can be loaded immediately.
    gears.timer.start_new(1, function()
        window_rules_manager.load_rules()
        return false
    end)
end

init()

return {
    window_rules_manager = window_rules_manager,
    rofi_manager = rofi_manager,
    -- Convenience function to open the main menu
    open_menu = rofi_manager.main_menu
}