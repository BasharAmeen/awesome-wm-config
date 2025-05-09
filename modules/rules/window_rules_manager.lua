--[[
    Window Rules Manager Module for AwesomeWM
    A module to manage window rules through a graphical interface
--]]

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local naughty = require("naughty")
local dpi = require("beautiful.xresources").apply_dpi

local window_rules_manager = {}

-- Helper function to add alpha channel to colors
local function add_alpha(color, alpha)
    if color:find("#") == 1 then
        local r, g, b
        -- Check if it's a 6-digit or 3-digit hex code
        if #color == 7 then -- #RRGGBB format
            r = tonumber("0x"..color:sub(2,3))
            g = tonumber("0x"..color:sub(4,5))
            b = tonumber("0x"..color:sub(6,7))
        elseif #color == 4 then -- #RGB format
            r = tonumber("0x"..color:sub(2,2)..color:sub(2,2))
            g = tonumber("0x"..color:sub(3,3)..color:sub(3,3))
            b = tonumber("0x"..color:sub(4,4)..color:sub(4,4))
        else
            return color
        end
        
        if r and g and b then
            -- Convert alpha from 0-1 to 0-255 and format as hex
            local a = math.floor(alpha * 255)
            return string.format("#%02x%02x%02x%02x", r, g, b, a)
        end
    end
    return color
end

-- Current rules storage
local current_rules = {}

-- Rules types and properties for UI
local rule_properties = {
    "border_width",
    "border_color",
    "floating",
    "maximized",
    "above",
    "below",
    "ontop",
    "sticky",
    "focusable",
    "titlebars_enabled",
    "placement",
    "tag"
}

local rule_types = {
    "class",
    "instance",
    "name",
    "role",
    "type"
}

-- Function to load current rules from awesome configuration
local function load_current_rules()
    current_rules = {}
    for i, rule in ipairs(awful.rules.rules) do
        if i > 1 then -- Skip the first rule (default rule for all clients)
            table.insert(current_rules, rule)
        end
    end
    return current_rules
end

-- Function to save rules to configuration
local function save_rules()
    -- This will only work if the module can modify the rules in memory
    -- For permanent changes, the user would need to save to rc.lua
    awful.rules.rules = {awful.rules.rules[1]} -- Keep default rule
    
    for _, rule in ipairs(current_rules) do
        table.insert(awful.rules.rules, rule)
    end
    
    -- Notify the user
    naughty.notify({
        title = "Window Rules Manager",
        text = "Rules applied. Restart Awesome to apply permanently.",
        timeout = 5
    })
end

-- Create a stylized text input widget
local function create_text_input(initial_value, width)
    local text_input = wibox.widget {
        text = initial_value or "",
        id = "value",
        widget = wibox.widget.textbox,
        forced_width = width or dpi(300)
    }
    
    local styled_input = wibox.widget {
        {
            text_input,
            left = dpi(10),
            right = dpi(10),
            top = dpi(5),
            bottom = dpi(5),
            widget = wibox.container.margin
        },
        bg = add_alpha(beautiful.bg_normal, 0.6),
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(4))
        end,
        border_width = dpi(1),
        border_color = beautiful.border_focus,
        widget = wibox.container.background
    }
    
    return {
        widget = styled_input,
        text_input = text_input
    }
end

-- Create a stylized button widget
local function create_button(text, bg_color)
    local button = wibox.widget {
        {
            {
                text = text,
                align = "center",
                widget = wibox.widget.textbox
            },
            margins = dpi(10),
            widget = wibox.container.margin
        },
        bg = bg_color or beautiful.bg_focus,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(4))
        end,
        widget = wibox.container.background
    }
    
    return button
end

-- Create a rule editor widget
local function create_rule_editor(rule_index)
    local rule = rule_index and current_rules[rule_index] or {
        rule = {},
        properties = {}
    }
    
    local editor_widget = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(10)
    }
    
    -- Rule matcher section
    local rule_matcher = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(5),
        {
            markup = "<b>Rule Matcher</b>",
            align = "left",
            widget = wibox.widget.textbox
        }
    }
    
    -- Add rule type entries
    local rule_entries = {}
    for _, type_name in ipairs(rule_types) do
        local type_value = ""
        
        -- If editing an existing rule
        if rule_index then
            if rule.rule[type_name] then
                type_value = rule.rule[type_name]
            elseif rule.rule_any and rule.rule_any[type_name] then
                if type(rule.rule_any[type_name]) == "table" then
                    type_value = table.concat(rule.rule_any[type_name], ", ")
                else
                    type_value = tostring(rule.rule_any[type_name])
                end
            end
        end
        
        local input = create_text_input(type_value)
        
        -- Handle text input
        input.widget:connect_signal("button::press", function()
            awful.prompt.run {
                prompt = type_name .. ": ",
                textbox = input.text_input,
                exe_callback = function(input_text)
                    input.text_input.text = input_text
                end
            }
        end)
        
        local entry = wibox.widget {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(10),
            {
                text = type_name .. ":",
                width = dpi(80),
                widget = wibox.widget.textbox
            },
            input.widget
        }
        
        rule_entries[type_name] = input
        rule_matcher:add(entry)
    end
    
    -- Rule properties section
    local rule_props = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(5),
        {
            markup = "<b>Properties</b>",
            align = "left",
            widget = wibox.widget.textbox
        }
    }
    
    -- Add property entries
    local property_entries = {}
    for _, prop_name in ipairs(rule_properties) do
        local prop_value = ""
        
        -- If editing an existing rule
        if rule_index and rule.properties and rule.properties[prop_name] ~= nil then
            if type(rule.properties[prop_name]) == "boolean" then
                prop_value = rule.properties[prop_name] and "true" or "false"
            else
                prop_value = tostring(rule.properties[prop_name])
            end
        end
        
        local input = create_text_input(prop_value)
        
        -- Handle text input
        input.widget:connect_signal("button::press", function()
            awful.prompt.run {
                prompt = prop_name .. ": ",
                textbox = input.text_input,
                exe_callback = function(input_text)
                    input.text_input.text = input_text
                end
            }
        end)
        
        local entry = wibox.widget {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(10),
            {
                text = prop_name .. ":",
                width = dpi(120),
                widget = wibox.widget.textbox
            },
            input.widget
        }
        
        property_entries[prop_name] = input
        rule_props:add(entry)
    end
    
    -- Add buttons with improved styling
    local buttons = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(20),
    }
    
    -- Save button
    local save_button = create_button(rule_index and "Update Rule" or "Add Rule", beautiful.bg_focus)
    
    -- Cancel button
    local cancel_button = create_button("Cancel", add_alpha(beautiful.bg_normal, 0.7))
    
    -- Function to save the rule
    local function save_rule()
        local new_rule = {
            rule = {},
            rule_any = {},
            properties = {}
        }
        
        -- Get values from rule entries
        for name, input in pairs(rule_entries) do
            local value = input.text_input.text
            if value and value ~= "" then
                -- Check if it's a comma-separated list
                if value:find(",") then
                    local values = {}
                    for v in value:gmatch("([^,]+)") do
                        table.insert(values, v:match("^%s*(.-)%s*$")) -- Trim spaces
                    end
                    if #values > 0 then
                        new_rule.rule_any[name] = values
                    end
                else
                    new_rule.rule[name] = value
                end
            end
        end
        
        -- Get values from property entries
        for name, input in pairs(property_entries) do
            local value = input.text_input.text
            if value and value ~= "" then
                if value == "true" then
                    new_rule.properties[name] = true
                elseif value == "false" then
                    new_rule.properties[name] = false
                elseif tonumber(value) then
                    new_rule.properties[name] = tonumber(value)
                else
                    new_rule.properties[name] = value
                end
            end
        end
        
        -- Update or add the rule
        if rule_index then
            current_rules[rule_index] = new_rule
        else
            table.insert(current_rules, new_rule)
        end
        
        -- Save rules to configuration
        save_rules()
        
        -- Close the editor popup
        if window_rules_manager.editor_popup then
            window_rules_manager.editor_popup.visible = false
        end
        
        -- Show updated rules in the main popup (recreate it)
        window_rules_manager.show()
    end
    
    -- Connect button signals
    save_button:connect_signal("button::press", save_rule)
    cancel_button:connect_signal("button::press", function()
        if window_rules_manager.editor_popup then
            window_rules_manager.editor_popup.visible = false
        end
    end)
    
    -- Add hover effect to buttons
    save_button:connect_signal("mouse::enter", function()
        save_button.bg = add_alpha(beautiful.bg_focus, 0.8)
    end)
    save_button:connect_signal("mouse::leave", function()
        save_button.bg = beautiful.bg_focus
    end)
    
    cancel_button:connect_signal("mouse::enter", function()
        cancel_button.bg = add_alpha(beautiful.bg_normal, 0.9)
    end)
    cancel_button:connect_signal("mouse::leave", function()
        cancel_button.bg = add_alpha(beautiful.bg_normal, 0.7)
    end)
    
    buttons:add(save_button)
    buttons:add(cancel_button)
    
    -- Add "Get Current Window" button for convenience
    local get_window_button = create_button("Get Current Window Properties", beautiful.bg_focus .. "80")
    
    -- Function to get current window properties and fill the form
    local function get_current_window()
        local c = client.focus
        if not c then
            naughty.notify({
                title = "Window Rules Manager",
                text = "No window is currently focused",
                timeout = 3
            })
            return
        end
        
        -- Fill rule entries with current window properties
        for _, type_name in ipairs(rule_types) do
            local value = c[type_name] or ""
            if value ~= "" then
                local input = rule_entries[type_name]
                if input then
                    input.text_input.text = value
                end
            end
        end
    end
    
    -- Connect button signal
    get_window_button:connect_signal("button::press", get_current_window)
    
    -- Add hover effect
    get_window_button:connect_signal("mouse::enter", function()
        get_window_button.bg = beautiful.bg_focus .. "A0"
    end)
    get_window_button:connect_signal("mouse::leave", function()
        get_window_button.bg = beautiful.bg_focus .. "80"
    end)
    
    -- Create a widget for the window properties button
    local window_button_widget = wibox.widget {
        layout = wibox.layout.align.horizontal,
        nil,
        get_window_button,
        nil
    }
    
    -- Assemble the editor widget
    editor_widget:add(rule_matcher)
    editor_widget:add(rule_props)
    editor_widget:add(window_button_widget)
    editor_widget:add(buttons)
    
    return editor_widget
end

-- Create a rule list widget
local function create_rule_list()
    local rules = load_current_rules()
    
    local rule_list = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(10),
        {
            markup = "<b>Current Window Rules</b>",
            align = "center",
            widget = wibox.widget.textbox
        }
    }
    
    -- No rules message
    if #rules == 0 then
        rule_list:add(wibox.widget {
            text = "No custom rules defined",
            align = "center",
            widget = wibox.widget.textbox
        })
    end
    
    -- Add rules to list
    for i, rule in ipairs(rules) do
        local rule_name = "Rule " .. i
        
        -- Try to determine a descriptive name for the rule
        if rule.rule and rule.rule.class then
            rule_name = "Class: " .. rule.rule.class
        elseif rule.rule and rule.rule.name then
            rule_name = "Name: " .. rule.rule.name
        elseif rule.rule_any and rule.rule_any.class then
            if type(rule.rule_any.class) == "table" then
                rule_name = "Classes: " .. table.concat(rule.rule_any.class, ", ")
            else
                rule_name = "Class: " .. tostring(rule.rule_any.class)
            end
        end
        
        -- Create rule entry
        local rule_entry = wibox.widget {
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(10),
            {
                text = rule_name,
                widget = wibox.widget.textbox
            },
            {
                text = "📝",  -- Edit icon
                widget = wibox.widget.textbox,
                buttons = gears.table.join(
                    awful.button({}, 1, function()
                        window_rules_manager.show_editor(i)
                    end)
                )
            },
            {
                text = "🗑️",  -- Delete icon
                widget = wibox.widget.textbox,
                buttons = gears.table.join(
                    awful.button({}, 1, function()
                        -- Remove rule
                        table.remove(current_rules, i)
                        -- Save rules
                        save_rules()
                        -- Refresh popup
                        window_rules_manager.show()
                    end)
                )
            }
        }
        
        rule_list:add(rule_entry)
    end
    
    -- Add buttons
    local buttons_layout = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(10),
    }
    
    -- Add "Add New Rule" button
    local add_button = create_button("+ Add New Rule", beautiful.bg_focus)
    add_button:connect_signal("button::press", function()
        window_rules_manager.show_editor()
    end)
    
    -- Add hover effect
    add_button:connect_signal("mouse::enter", function()
        add_button.bg = add_alpha(beautiful.bg_focus, 0.8)
    end)
    add_button:connect_signal("mouse::leave", function()
        add_button.bg = beautiful.bg_focus
    end)
    
    -- Add "Export Rules" button
    local export_button = create_button("Export Rules", add_alpha(beautiful.bg_normal, 0.7))
    export_button:connect_signal("button::press", function()
        window_rules_manager.export_rules()
    end)
    
    -- Add hover effect
    export_button:connect_signal("mouse::enter", function()
        export_button.bg = add_alpha(beautiful.bg_normal, 0.9)
    end)
    export_button:connect_signal("mouse::leave", function()
        export_button.bg = add_alpha(beautiful.bg_normal, 0.7)
    end)
    
    -- Add "Import Rules" button
    local import_button = create_button("Import Rules", add_alpha(beautiful.bg_normal, 0.7))
    import_button:connect_signal("button::press", function()
        window_rules_manager.import_rules()
    end)
    
    -- Add hover effect
    import_button:connect_signal("mouse::enter", function()
        import_button.bg = add_alpha(beautiful.bg_normal, 0.9)
    end)
    import_button:connect_signal("mouse::leave", function()
        import_button.bg = add_alpha(beautiful.bg_normal, 0.7)
    end)
    
    -- Add "Check Matching Rules" button
    local check_button = create_button("Check Matching Rules", add_alpha(beautiful.bg_focus, 0.6))
    check_button:connect_signal("button::press", function()
        window_rules_manager.check_matching_rules()
    end)
    
    -- Add hover effect
    check_button:connect_signal("mouse::enter", function()
        check_button.bg = add_alpha(beautiful.bg_focus, 0.8)
    end)
    check_button:connect_signal("mouse::leave", function()
        check_button.bg = add_alpha(beautiful.bg_focus, 0.6)
    end)
    
    -- Add buttons to layout
    buttons_layout:add(add_button)
    buttons_layout:add(export_button)
    buttons_layout:add(import_button)
    
    -- Create a second row for additional buttons
    local buttons_row2 = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = dpi(10),
    }
    
    buttons_row2:add(check_button)
    
    -- Add buttons container
    local buttons_container = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(10),
        {
            layout = wibox.layout.align.horizontal,
            nil,
            buttons_layout,
            nil
        },
        {
            layout = wibox.layout.align.horizontal,
            nil,
            buttons_row2,
            nil
        }
    }
    
    rule_list:add(buttons_container)
    
    return rule_list
end

-- Show the main rules manager popup
function window_rules_manager.show()
    -- Direct container for content
    local content_container = wibox.widget {
        layout = wibox.layout.fixed.vertical,
    }
    
    -- Add the rule list directly to the container
    local success, rule_list = pcall(create_rule_list)
    if success and rule_list then
        content_container:add(rule_list)
    else
        content_container:add(wibox.widget {
            text = "Error loading rules list",
            align = "center",
            widget = wibox.widget.textbox
        })
    end
    
    -- Create a new popup each time
    if window_rules_manager.popup and window_rules_manager.popup.visible then
        window_rules_manager.popup.visible = false
    end
    
    -- Create a new popup with the content directly embedded
    window_rules_manager.popup = awful.popup {
        ontop = true,
        visible = false,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(10))
        end,
        border_width = dpi(2),
        border_color = beautiful.border_focus,
        maximum_width = dpi(500),
        maximum_height = dpi(600),
        bg = add_alpha(beautiful.bg_normal, 0.95),
        widget = {
            {
                content_container,
                margins = dpi(20),
                widget = wibox.container.margin
            },
            layout = wibox.layout.fixed.vertical
        }
    }
    
    -- Show the popup
    window_rules_manager.popup.visible = true
    awful.placement.centered(window_rules_manager.popup)
end

-- Show the rule editor popup
function window_rules_manager.show_editor(rule_index)
    -- Direct container for content
    local content_container = wibox.widget {
        layout = wibox.layout.fixed.vertical,
    }
    
    -- Add the rule editor directly to the container
    local success, editor = pcall(function() return create_rule_editor(rule_index) end)
    if success and editor then
        content_container:add(editor)
    else
        content_container:add(wibox.widget {
            text = "Error loading rule editor",
            align = "center",
            widget = wibox.widget.textbox
        })
    end
    
    -- Create a new popup each time
    if window_rules_manager.editor_popup and window_rules_manager.editor_popup.visible then
        window_rules_manager.editor_popup.visible = false
    end
    
    -- Create a new popup with the content directly embedded
    window_rules_manager.editor_popup = awful.popup {
        ontop = true,
        visible = false,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(10))
        end,
        border_width = dpi(2),
        border_color = beautiful.border_focus,
        maximum_width = dpi(600),
        maximum_height = dpi(700),
        bg = add_alpha(beautiful.bg_normal, 0.95),
        widget = {
            {
                content_container,
                margins = dpi(20),
                widget = wibox.container.margin
            },
            layout = wibox.layout.fixed.vertical
        }
    }
    
    -- Show the popup
    window_rules_manager.editor_popup.visible = true
    awful.placement.centered(window_rules_manager.editor_popup)
end

-- Helper function to get window properties for the currently focused client
function window_rules_manager.get_focused_window_properties()
    local c = client.focus
    if not c then
        naughty.notify({
            title = "Window Rules Manager",
            text = "No window is currently focused",
            timeout = 3
        })
        return
    end
    
    -- Get window properties
    local props = {
        class = c.class or "",
        instance = c.instance or "",
        name = c.name or "",
        role = c.role or "",
        type = c.type or ""
    }
    
    -- Create a notification with the properties
    local text = "Window Properties:\n"
    for k, v in pairs(props) do
        if v and v ~= "" then
            text = text .. k .. ": " .. v .. "\n"
        end
    end
    
    naughty.notify({
        title = "Window Rules Manager",
        text = text,
        timeout = 0
    })
end

-- Helper function to check which rules match the current window
function window_rules_manager.check_matching_rules()
    local c = client.focus
    if not c then
        naughty.notify({
            title = "Window Rules Manager",
            text = "No window is currently focused",
            timeout = 3
        })
        return
    end
    
    -- Get all rules
    local rules = load_current_rules()
    local matching_rules = {}
    
    -- Check each rule for a match
    for i, rule in ipairs(rules) do
        local matches = true
        
        -- Check rule matchers
        if rule.rule then
            for prop, value in pairs(rule.rule) do
                if c[prop] ~= value then
                    matches = false
                    break
                end
            end
        end
        
        -- Check rule_any matchers if still matching
        if matches and rule.rule_any then
            for prop, values in pairs(rule.rule_any) do
                if type(values) == "table" then
                    local found = false
                    for _, value in ipairs(values) do
                        if c[prop] == value then
                            found = true
                            break
                        end
                    end
                    if not found then
                        matches = false
                        break
                    end
                else
                    if c[prop] ~= values then
                        matches = false
                        break
                    end
                end
            end
        end
        
        -- Add to matching rules if it matches
        if matches then
            table.insert(matching_rules, {index = i, rule = rule})
        end
    end
    
    -- Display matching rules
    if #matching_rules == 0 then
        naughty.notify({
            title = "Window Rules Manager",
            text = "No rules match the current window",
            timeout = 5
        })
    else
        local text = "Matching rules for current window:\n"
        for _, match in ipairs(matching_rules) do
            local rule_name = "Rule " .. match.index
            
            -- Try to determine a descriptive name for the rule
            if match.rule.rule and match.rule.rule.class then
                rule_name = "Class: " .. match.rule.rule.class
            elseif match.rule.rule and match.rule.rule.name then
                rule_name = "Name: " .. match.rule.rule.name
            elseif match.rule.rule_any and match.rule.rule_any.class then
                if type(match.rule.rule_any.class) == "table" then
                    rule_name = "Classes: " .. table.concat(match.rule.rule_any.class, ", ")
                else
                    rule_name = "Class: " .. tostring(match.rule.rule_any.class)
                end
            end
            
            text = text .. "- " .. rule_name .. "\n"
        end
        
        naughty.notify({
            title = "Window Rules Manager",
            text = text,
            timeout = 0  -- Show until dismissed
        })
    end
end

-- Function to export rules to a file
function window_rules_manager.export_rules()
    local rules = load_current_rules()
    local rules_code = "-- Window rules\nawful.rules.rules = {\n"
    
    -- Add the default rule
    rules_code = rules_code .. "    -- All clients will match this rule\n"
    rules_code = rules_code .. "    { rule = { },\n"
    rules_code = rules_code .. "      properties = { border_width = beautiful.border_width,\n"
    rules_code = rules_code .. "                     border_color = beautiful.border_normal,\n"
    rules_code = rules_code .. "                     callback = awful.client.setslave,\n"
    rules_code = rules_code .. "                     focus = awful.client.focus.filter,\n"
    rules_code = rules_code .. "                     raise = true,\n"
    rules_code = rules_code .. "                     keys = clientkeys,\n"
    rules_code = rules_code .. "                     buttons = clientbuttons,\n"
    rules_code = rules_code .. "                     screen = awful.screen.preferred,\n"
    rules_code = rules_code .. "                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,\n"
    rules_code = rules_code .. "                     size_hints_honor = false\n"
    rules_code = rules_code .. "     },\n"
    rules_code = rules_code .. "     callback = function (c)\n"
    rules_code = rules_code .. "        awful.client.setmaster(c)\n"
    rules_code = rules_code .. "    end\n"
    rules_code = rules_code .. "    },\n\n"
    
    -- Add custom rules
    for _, rule in ipairs(rules) do
        rules_code = rules_code .. "    {\n"
        
        -- Rule matchers
        if next(rule.rule) ~= nil then
            rules_code = rules_code .. "      rule = {"
            local first = true
            for k, v in pairs(rule.rule) do
                if not first then
                    rules_code = rules_code .. ", "
                end
                if type(v) == "string" then
                    rules_code = rules_code .. k .. ' = "' .. v .. '"'
                else
                    rules_code = rules_code .. k .. " = " .. tostring(v)
                end
                first = false
            end
            rules_code = rules_code .. "},\n"
        end
        
        -- Rule any matchers
        if rule.rule_any and next(rule.rule_any) ~= nil then
            rules_code = rules_code .. "      rule_any = {"
            local first = true
            for k, v in pairs(rule.rule_any) do
                if not first then
                    rules_code = rules_code .. ", "
                end
                if type(v) == "table" then
                    rules_code = rules_code .. k .. ' = {'
                    local first_item = true
                    for _, item in ipairs(v) do
                        if not first_item then
                            rules_code = rules_code .. ", "
                        end
                        rules_code = rules_code .. '"' .. item .. '"'
                        first_item = false
                    end
                    rules_code = rules_code .. '}'
                elseif type(v) == "string" then
                    rules_code = rules_code .. k .. ' = "' .. v .. '"'
                else
                    rules_code = rules_code .. k .. " = " .. tostring(v)
                end
                first = false
            end
            rules_code = rules_code .. "},\n"
        end
        
        -- Properties
        if next(rule.properties) ~= nil then
            rules_code = rules_code .. "      properties = {"
            local first = true
            for k, v in pairs(rule.properties) do
                if not first then
                    rules_code = rules_code .. ", "
                end
                if type(v) == "string" then
                    rules_code = rules_code .. k .. ' = "' .. v .. '"'
                else
                    rules_code = rules_code .. k .. " = " .. tostring(v)
                end
                first = false
            end
            rules_code = rules_code .. "}\n"
        end
        
        rules_code = rules_code .. "    },\n"
    end
    
    rules_code = rules_code .. "}\n"
    
    -- Save to file
    local file_path = os.getenv("HOME") .. "/.config/awesome/modules/rules/custom_rules.lua"
    local file = io.open(file_path, "w")
    if file then
        file:write(rules_code)
        file:close()
        
        naughty.notify({
            title = "Window Rules Manager",
            text = "Rules exported to " .. file_path,
            timeout = 5
        })
        
        return true
    else
        naughty.notify({
            title = "Window Rules Manager",
            text = "Failed to export rules to " .. file_path,
            timeout = 5
        })
        
        return false
    end
end

-- Function to import rules from the exported file
function window_rules_manager.import_rules()
    local file_path = os.getenv("HOME") .. "/.config/awesome/modules/rules/custom_rules.lua"
    local file = io.open(file_path, "r")
    
    if not file then
        naughty.notify({
            title = "Window Rules Manager",
            text = "No custom rules file found at " .. file_path,
            timeout = 5
        })
        return false
    end
    
    -- Close the file, we don't actually read it directly
    file:close()
    
    -- Execute the file to get the rules
    local success, result = pcall(function()
        -- Create a temporary file that returns the rules
        local temp_file_path = os.getenv("HOME") .. "/.config/awesome/modules/rules/temp_rules.lua"
        local temp_file = io.open(temp_file_path, "w")
        
        if temp_file then
            -- Read the custom_rules.lua file
            local custom_file = io.open(file_path, "r")
            if custom_file then
                -- Start with a return statement so we can get the rules table
                temp_file:write("local awful = require('awful')\n")
                temp_file:write("local beautiful = require('beautiful')\n")
                temp_file:write("-- Define necessary globals to avoid errors\n")
                temp_file:write("clientkeys = clientkeys or {}\n")
                temp_file:write("clientbuttons = clientbuttons or {}\n")
                temp_file:write("-- Include the custom rules\n")
                
                -- Copy the content of the custom rules file
                local content = custom_file:read("*all")
                temp_file:write(content)
                
                -- Add return statement
                temp_file:write("\nreturn awful.rules.rules")
                
                custom_file:close()
                temp_file:close()
                
                -- Load the temporary file to get the rules
                local loaded_rules = dofile(temp_file_path)
                
                -- Remove the temporary file
                os.remove(temp_file_path)
                
                -- Apply the loaded rules
                if loaded_rules and #loaded_rules > 0 then
                    awful.rules.rules = loaded_rules
                    current_rules = {}
                    for i = 2, #loaded_rules do
                        table.insert(current_rules, loaded_rules[i])
                    end
                    
                    naughty.notify({
                        title = "Window Rules Manager",
                        text = "Successfully imported " .. (#loaded_rules - 1) .. " rules from " .. file_path,
                        timeout = 5
                    })
                    
                    -- Refresh the UI if open
                    if window_rules_manager.popup and window_rules_manager.popup.visible then
                        window_rules_manager.show()
                    end
                    
                    return true
                end
            else
                os.remove(temp_file_path)
                error("Could not open custom rules file")
            end
        else
            error("Could not create temporary file")
        end
    end)
    
    if not success then
        naughty.notify({
            title = "Window Rules Manager",
            text = "Error importing rules: " .. tostring(result),
            timeout = 5
        })
        return false
    end
    
    return true
end

-- Toggle the window rules manager
function window_rules_manager.toggle()
    if window_rules_manager.popup and window_rules_manager.popup.visible then
        window_rules_manager.popup.visible = false
    else
        window_rules_manager.show()
    end
end

return window_rules_manager 