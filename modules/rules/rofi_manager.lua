--[[
    Rofi Manager for Window Rules
    Handles interaction with Rofi for managing window rules
--]]

local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local window_rules_manager = require("modules.rules.window_rules_manager")

local rofi_manager = {}

-- Function to run rofi command and get output
local function run_rofi(prompt, items, callback)
    local input = ""
    for _, item in ipairs(items) do
        input = input .. item .. "\n"
    end
    
    -- Escape input for shell
    input = input:gsub("'", "'\\''")
    
    awful.spawn.easy_async_with_shell(
        string.format("echo '%s' | rofi -dmenu -p '%s' -format s", input, prompt),
        function(stdout)
            local selection = stdout:gsub("\n", "")
            if selection ~= "" then
                callback(selection)
            end
        end
    )
end

-- Main menu for rules manager
function rofi_manager.main_menu()
    local options = {
        "➕ Add Rule for Focused Window",
        "📝 Edit Existing Rules",
        "💾 Save & Apply Rules",
        "📤 Export Rules",
        "📥 Import Rules"
    }
    
    run_rofi("Rules Manager", options, function(selection)
        if selection:find("Add Rule") then
            rofi_manager.add_rule_menu()
        elseif selection:find("Edit Existing Rules") then
            rofi_manager.edit_rules_menu()
        elseif selection:find("Save") then
            window_rules_manager.save_rules()
        elseif selection:find("Export") then
            window_rules_manager.export_rules()
        elseif selection:find("Import") then
            window_rules_manager.import_rules()
        end
    end)
end

-- Menu to add a rule based on focused window
function rofi_manager.add_rule_menu()
    local c = client.focus
    if not c then
        naughty.notify({ text = "No window focused", preset = naughty.config.presets.critical })
        return
    end

    local options = {
        "Match by Class: " .. (c.class or "N/A"),
        "Match by Instance: " .. (c.instance or "N/A"),
        "Match by Name: " .. (c.name or "N/A")
    }

    run_rofi("Add Rule", options, function(selection)
        local rule_part = {}
        if selection:find("Class") then
            rule_part = { class = c.class }
        elseif selection:find("Instance") then
            rule_part = { instance = c.instance }
        elseif selection:find("Name") then
            rule_part = { name = c.name }
        end
        
        -- After selecting match criteria, select properties
        rofi_manager.select_properties_menu(rule_part)
    end)
end

-- Menu to select properties for the new rule
function rofi_manager.select_properties_menu(rule_part)
    local property_options = {
        "Floating: true",
        "Floating: false",
        "Tag: 1", "Tag: 2", "Tag: 3", "Tag: 4", "Tag: 5", "Tag: 6", "Tag: 7",
        "Placement: Centered",
        "Titlebars: true",
        "Titlebars: false",
        "Maximized: true",
        "Maximized: false",
        "OnTop: true",
        "OnTop: false",
        "Sticky: true",
        "Sticky: false",
        "Fullscreen: true",
        "Fullscreen: false",
        "Focusable: true",
        "Focusable: false",
        "DONE"
    }
    
    local selected_props = {}
    
    local function show_props_menu()
        -- Build prompt with currently selected properties
        local prompt = "Select Properties (Pick multiple, then DONE)"
        if next(selected_props) then
            prompt = prompt .. " [Selected: "
            local first = true
            for k, v in pairs(selected_props) do
                if not first then prompt = prompt .. ", " end
                prompt = prompt .. k .. "=" .. tostring(v)
                first = false
            end
            prompt = prompt .. "]"
        end

        run_rofi(prompt, property_options, function(selection)
            if selection == "DONE" then
                -- Create the rule
                local new_rule = {
                    rule = rule_part,
                    properties = selected_props
                }
                
                -- Add to manager
                window_rules_manager.add_rule(new_rule)
                
            elseif selection:find("Floating: true") then
                selected_props.floating = true
                show_props_menu() 
            elseif selection:find("Floating: false") then
                selected_props.floating = false
                show_props_menu()
            elseif selection:find("Tag:") then
                local tag_num = selection:match("Tag: (%d+)")
                selected_props.tag = tag_num
                show_props_menu()
            elseif selection:find("Placement: Centered") then
                -- Note: This is simplified, actual placement might need awful.placement object
                selected_props.placement = awful.placement.centered
                show_props_menu()
            elseif selection:find("Titlebars: true") then
                selected_props.titlebars_enabled = true
                show_props_menu()
            elseif selection:find("Titlebars: false") then
                selected_props.titlebars_enabled = false
                show_props_menu()
            elseif selection:find("Maximized: true") then
                selected_props.maximized = true
                show_props_menu()
            elseif selection:find("Maximized: false") then
                selected_props.maximized = false
                show_props_menu()
            elseif selection:find("OnTop: true") then
                selected_props.ontop = true
                show_props_menu()
            elseif selection:find("OnTop: false") then
                selected_props.ontop = false
                show_props_menu()
            elseif selection:find("Sticky: true") then
                selected_props.sticky = true
                show_props_menu()
            elseif selection:find("Sticky: false") then
                selected_props.sticky = false
                show_props_menu()
            elseif selection:find("Fullscreen: true") then
                selected_props.fullscreen = true
                show_props_menu()
            elseif selection:find("Fullscreen: false") then
                selected_props.fullscreen = false
                show_props_menu()
            elseif selection:find("Focusable: true") then
                selected_props.focusable = true
                show_props_menu()
            elseif selection:find("Focusable: false") then
                selected_props.focusable = false
                show_props_menu()
            end
        end)
    end
    
    show_props_menu()
end

-- Menu to edit existing rules
function rofi_manager.edit_rules_menu()
    local rules = window_rules_manager.get_custom_rules()
    if #rules == 0 then
        naughty.notify({ text = "No custom rules to edit" })
        return
    end

    local items = {}
    for i, rule in ipairs(rules) do
        local desc = "Rule " .. i
        if rule.rule then
            for k, v in pairs(rule.rule) do
                desc = desc .. " [" .. k .. "=" .. tostring(v) .. "]"
            end
        end
        table.insert(items, desc)
    end
    table.insert(items, "BACK")

    run_rofi("Select Rule to Delete", items, function(selection)
        if selection == "BACK" then
            rofi_manager.main_menu()
            return
        end
        
        local index = tonumber(selection:match("^Rule (%d+)"))
        if index then
            -- For now simpler to just offer delete, editing complex tables in Rofi is hard
            run_rofi("Action for Rule " .. index, {"🗑️ Delete Rule", "❌ Cancel"}, function(action) 
                if action:find("Delete") then
                    window_rules_manager.remove_rule(index)
                    rofi_manager.edit_rules_menu()
                else
                    rofi_manager.edit_rules_menu()
                end
            end)
        end
    end)
end

return rofi_manager
