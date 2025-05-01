---------------------------------------------------------
-- Notification Center - Panel Module
-- UI panel for displaying notifications
---------------------------------------------------------

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local naughty = require("naughty")

local history = require("modules.notification_center.history")
local actions = require("modules.notification_center.actions")

-- Define the panel module
local panel = {}
panel.visible = false

-- Initialize the module
function panel.init(config)
    panel.config = config
    panel.create_panel()
    return panel
end

-- Create the main panel
function panel.create_panel()
    -- Get screen dimensions
    local s = awful.screen.focused()
    
    -- Create panel wibox
    panel.box = wibox({
        ontop = true,
        visible = false,
        type = "dock",
        screen = s,
        bg = beautiful.bg_normal .. "CC", -- Semi-transparent background
        width = panel.config.width,
        height = s.workarea.height,
        x = panel.config.position == "right" and (s.workarea.width - panel.config.width) or 0,
        y = s.workarea.y
    })
    
    -- Panel shape for rounded corners
    panel.box.shape = function(cr, w, h)
        gears.shape.partially_rounded_rect(
            cr, w, h, 
            panel.config.position ~= "right", -- left top corner
            panel.config.position == "right", -- right top corner
            panel.config.position == "right", -- right bottom corner
            panel.config.position ~= "right", -- left bottom corner
            dpi(12) -- radius
        )
    end
    
    -- Set up close on click outside
    panel.setup_close_outside()
    
    -- Create panel content
    panel.setup_content()
    
    -- Setup panel animations
    panel.setup_animations()
    
    -- Update panel when notifications change
    history.connect_signal("notification_added", function() panel.update_content() end)
    history.connect_signal("notification_removed", function() panel.update_content() end)
    history.connect_signal("notification_read", function() panel.update_content() end)
    history.connect_signal("cleared", function() panel.update_content() end)
    history.connect_signal("app_cleared", function() panel.update_content() end)
    
    -- Update panel when screen changes
    awful.screen.connect_for_each_screen(function(scr)
        if scr == panel.box.screen then
            panel.update_position()
        end
    end)
    
    return panel.box
end

-- Update panel position based on screen size
function panel.update_position()
    local s = panel.box.screen or awful.screen.focused()
    
    panel.box.height = s.workarea.height
    panel.box.x = panel.config.position == "right" and (s.workarea.width - panel.config.width) or 0
    panel.box.y = s.workarea.y
end

-- Set up content for the panel
function panel.setup_content()
    -- Header with search, do not disturb, and clear buttons
    local header = panel.create_header()
    
    -- Notifications area
    panel.notifications_area = panel.create_notifications_area()
    
    -- Empty state when no notifications
    panel.empty_state = panel.create_empty_state()
    
    -- Put everything together
    panel.box:setup {
        {
            {
                header,
                {
                    panel.notifications_area,
                    panel.empty_state,
                    layout = wibox.layout.stack
                },
                layout = wibox.layout.fixed.vertical
            },
            margins = dpi(20),
            widget = wibox.container.margin
        },
        bg = beautiful.bg_normal .. "DD",
        widget = wibox.container.background
    }
    
    -- Initial update
    panel.update_content()
end

-- Create header with search and buttons
function panel.create_header()
    -- Create search input
    local search_input = wibox.widget {
        {
            {
                id = "icon",
                text = "",
                font = "FontAwesome 12",
                widget = wibox.widget.textbox
            },
            {
                id = "text",
                text = "Search notifications...",
                widget = wibox.widget.textbox
            },
            spacing = dpi(10),
            layout = wibox.layout.fixed.horizontal
        },
        id = "search_container",
        bg = beautiful.bg_normal .. "99",
        shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dpi(6)) end,
        widget = wibox.container.background
    }
    
    -- Create DND toggle
    local dnd_button = wibox.widget {
        {
            id = "icon",
            text = "",
            font = "FontAwesome 14",
            align = "center",
            widget = wibox.widget.textbox
        },
        id = "dnd_container",
        bg = beautiful.bg_normal,
        shape = function(cr, w, h) gears.shape.circle(cr, w, h) end,
        forced_width = dpi(36),
        forced_height = dpi(36),
        widget = wibox.container.background
    }
    
    -- Create clear all button
    local clear_button = wibox.widget {
        {
            id = "icon",
            text = "",
            font = "FontAwesome 14",
            align = "center",
            widget = wibox.widget.textbox
        },
        id = "clear_container",
        bg = beautiful.bg_normal,
        shape = function(cr, w, h) gears.shape.circle(cr, w, h) end,
        forced_width = dpi(36),
        forced_height = dpi(36),
        widget = wibox.container.background
    }
    
    -- Title widget
    local title = wibox.widget {
        markup = "<b>Notifications</b>",
        font = beautiful.font,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }
    
    -- Group the widgets
    local header = wibox.widget {
        {
            {
                title,
                nil,
                {
                    dnd_button,
                    clear_button,
                    spacing = dpi(10),
                    layout = wibox.layout.fixed.horizontal
                },
                layout = wibox.layout.align.horizontal
            },
            search_input,
            spacing = dpi(15),
            layout = wibox.layout.fixed.vertical
        },
        margins = {bottom = dpi(10)},
        widget = wibox.container.margin
    }
    
    -- Wire up button actions
    clear_button:buttons(gears.table.join(
        awful.button({}, 1, function()
            history.clear_all()
            panel.update_content()
        end)
    ))
    
    -- DND toggle functionality
    local dnd_enabled = false
    dnd_button:buttons(gears.table.join(
        awful.button({}, 1, function()
            dnd_enabled = not dnd_enabled
            
            local icon_widget = dnd_button:get_children_by_id("icon")[1]
            local container_widget = dnd_button:get_children_by_id("dnd_container")[1]
            
            if dnd_enabled then
                icon_widget.markup = "<span foreground='" .. beautiful.bg_normal .. "'></span>"
                container_widget.bg = beautiful.bg_urgent
                -- Enable DND mode
                naughty.suspend()
            else
                icon_widget.markup = ""
                container_widget.bg = beautiful.bg_normal
                -- Disable DND mode
                naughty.resume()
            end
        end)
    ))
    
    -- Implement search functionality
    local search_mode = false
    local search_term = ""
    
    search_input:buttons(gears.table.join(
        awful.button({}, 1, function()
            search_mode = true
            local text_widget = search_input:get_children_by_id("text")[1]
            text_widget.text = ""
            
            -- Set up keyboard grabbing for search
            awful.prompt.run {
                prompt = "",
                textbox = text_widget,
                exe_callback = function(input)
                    search_term = input
                    search_mode = false
                    
                    if input == "" then
                        text_widget.text = "Search notifications..."
                    else
                        text_widget.text = input
                    end
                    
                    panel.update_content(search_term)
                end,
                done_callback = function()
                    search_mode = false
                    if search_term == "" then
                        text_widget.text = "Search notifications..."
                    end
                end
            }
        end)
    ))
    
    return header
end

-- Create notifications area
function panel.create_notifications_area()
    local scroll_container = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(10),
    }
    
    local scrollbox = wibox.widget {
        scroll_container,
        forced_height = dpi(800),
        layout = wibox.layout.fixed.vertical
    }
    
    return wibox.widget {
        scrollbox,
        id = "scrollbox",
        layout = wibox.container.scroll.vertical,
        step = 50,
        fps = 60
    }
end

-- Create empty state widget
function panel.create_empty_state()
    return wibox.widget {
        {
            {
                {
                    id = "icon",
                    text = "",
                    font = "FontAwesome 40",
                    align = "center",
                    valign = "center",
                    opacity = 0.5,
                    widget = wibox.widget.textbox
                },
                {
                    id = "text",
                    markup = "<span foreground='" .. beautiful.fg_normal .. "80'><b>No notifications</b></span>",
                    align = "center",
                    valign = "center",
                    widget = wibox.widget.textbox
                },
                spacing = dpi(10),
                layout = wibox.layout.fixed.vertical
            },
            valign = "center",
            halign = "center",
            layout = wibox.container.place
        },
        forced_height = dpi(700),
        widget = wibox.container.background
    }
end

-- Create notification widget
function panel.create_notification_widget(notification)
    -- Create action buttons
    local action_buttons = wibox.widget {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(5)
    }
    
    local notif_actions = actions.get_actions(notification)
    
    for _, action in ipairs(notif_actions) do
        local btn = wibox.widget {
            {
                {
                    text = action.name,
                    align = "center",
                    valign = "center",
                    widget = wibox.widget.textbox
                },
                margins = {
                    top = dpi(4),
                    bottom = dpi(4),
                    left = dpi(8),
                    right = dpi(8)
                },
                widget = wibox.container.margin
            },
            bg = beautiful.bg_normal .. "99",
            shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dpi(4)) end,
            widget = wibox.container.background
        }
        
        -- Connect button click
        btn:buttons(gears.table.join(
            awful.button({}, 1, function()
                if action.key == "dismiss" then
                    actions.dismiss(notification)
                    history.mark_as_read(notification)
                    panel.update_content()
                elseif action.callback then
                    action.callback(notification)
                    history.mark_as_read(notification)
                    panel.update_content()
                else
                    actions.execute(notification, action.key)
                    history.mark_as_read(notification)
                    panel.update_content()
                end
            end)
        ))
        
        action_buttons:add(btn)
    end
    
    -- Format timestamp
    local timestamp = os.date("%H:%M", notification.timestamp or os.time())
    
    -- Create notification widget
    local widget = wibox.widget {
        {
            {
                {
                    {
                        {
                            {
                                text = notification.app_name or "Unknown",
                                font = beautiful.font,
                                align = "left",
                                valign = "center",
                                widget = wibox.widget.textbox
                            },
                            nil,
                            {
                                text = timestamp,
                                font = beautiful.font,
                                align = "right",
                                valign = "center",
                                widget = wibox.widget.textbox
                            },
                            layout = wibox.layout.align.horizontal
                        },
                        {
                            markup = "<b>" .. (notification.title or "") .. "</b>",
                            align = "left",
                            valign = "center",
                            widget = wibox.widget.textbox
                        },
                        {
                            text = notification.message or "",
                            align = "left",
                            valign = "center",
                            widget = wibox.widget.textbox
                        },
                        spacing = dpi(4),
                        layout = wibox.layout.fixed.vertical
                    },
                    margins = dpi(8),
                    widget = wibox.container.margin
                },
                id = "background",
                bg = notification.read and (beautiful.bg_normal .. "80") or beautiful.bg_normal,
                shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dpi(8)) end,
                widget = wibox.container.background
            },
            action_buttons,
            spacing = dpi(8),
            layout = wibox.layout.fixed.vertical
        },
        margins = {bottom = dpi(10)},
        widget = wibox.container.margin
    }
    
    -- Create hover effect
    local container_bg = widget:get_children_by_id("background")[1]
    
    container_bg:connect_signal("mouse::enter", function()
        container_bg.bg = beautiful.bg_focus .. "99"
    end)
    
    container_bg:connect_signal("mouse::leave", function()
        container_bg.bg = notification.read and (beautiful.bg_normal .. "80") or beautiful.bg_normal
    end)
    
    -- Add click handler to mark as read
    container_bg:buttons(gears.table.join(
        awful.button({}, 1, function()
            history.mark_as_read(notification)
            panel.update_content()
        end)
    ))
    
    return widget
end

-- Create app section widget
function panel.create_app_section(app_data)
    -- Create header
    local header = wibox.widget {
        {
            {
                text = app_data.name or "Unknown",
                font = beautiful.font,
                align = "left",
                valign = "center",
                widget = wibox.widget.textbox
            },
            nil,
            {
                {
                    {
                        text = "",
                        font = "FontAwesome 11",
                        align = "center",
                        valign = "center",
                        widget = wibox.widget.textbox
                    },
                    bg = beautiful.bg_normal,
                    shape = function(cr, w, h) gears.shape.circle(cr, w, h) end,
                    forced_width = dpi(24),
                    forced_height = dpi(24),
                    widget = wibox.container.background
                },
                margins = {right = dpi(4)},
                widget = wibox.container.margin
            },
            layout = wibox.layout.align.horizontal
        },
        margins = {bottom = dpi(8), top = dpi(8)},
        widget = wibox.container.margin
    }
    
    -- Add clear button functionality
    local clear_btn = header:get_children_by_id("background")[1]
    if clear_btn then
        clear_btn:buttons(gears.table.join(
            awful.button({}, 1, function()
                history.clear_app(app_data.name)
                panel.update_content()
            end)
        ))
    end
    
    -- Create container for notifications
    local notifications_container = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(5)
    }
    
    -- Add notifications to container
    for _, notification in ipairs(app_data.notifications) do
        notifications_container:add(panel.create_notification_widget(notification))
    end
    
    -- Create section widget
    local section = wibox.widget {
        header,
        notifications_container,
        layout = wibox.layout.fixed.vertical
    }
    
    return section
end

-- Update panel content
function panel.update_content(search_term)
    local notifications_area = panel.notifications_area:get_children_by_id("scrollbox")[1]
    notifications_area:reset()
    
    local notifications
    
    if search_term and search_term ~= "" then
        -- Show filtered notifications
        notifications = history.filter(search_term)
        
        -- Create widgets for filtered notifications
        for _, notification in ipairs(notifications) do
            notifications_area:add(panel.create_notification_widget(notification))
        end
    else
        -- Show notifications grouped by app
        local apps = history.get_by_app()
        
        for _, app_data in ipairs(apps) do
            notifications_area:add(panel.create_app_section(app_data))
        end
    end
    
    -- Show empty state if no notifications
    local has_notifications = (search_term and search_term ~= "") 
        and #history.filter(search_term) > 0
        or #history.get_all() > 0
    
    panel.empty_state.visible = not has_notifications
    panel.notifications_area.visible = has_notifications
end

-- Set up closing when clicking outside
function panel.setup_close_outside()
    local outside_click_detector = wibox({
        ontop = true,
        screen = panel.box.screen,
        bg = "#00000000",
        type = "utility",
        height = screen.primary.geometry.height,
        width = screen.primary.geometry.width,
        x = 0,
        y = 0
    })
    
    outside_click_detector:buttons(
        gears.table.join(
            awful.button({}, 1, function()
                panel.hide()
            end)
        )
    )
    
    panel.outside_click_detector = outside_click_detector
end

-- Set up animations
function panel.setup_animations()
    panel.animation_dir = panel.config.position == "right" and 1 or -1
    panel.anim_status = "closed"
    
    -- Slide-in animation
    function panel.animate_open()
        if panel.anim_status == "opening" then
            return
        end
        panel.anim_status = "opening"
        
        local start_x = panel.config.position == "right" 
            and panel.box.screen.geometry.width 
            or -panel.config.width
            
        local end_x = panel.config.position == "right"
            and (panel.box.screen.geometry.width - panel.config.width)
            or 0
            
        panel.box.x = start_x
        panel.box.visible = true
        panel.outside_click_detector.visible = false
        
        local anim_steps = 20
        local step = 0
        local timer = gears.timer.start_new(0.005, function()
            step = step + 1
            panel.box.x = start_x + ((end_x - start_x) * (step / anim_steps))
            
            if step == anim_steps then
                panel.anim_status = "opened"
                panel.box.x = end_x
                panel.outside_click_detector.visible = true
                return false
            end
            
            return true
        end)
    end
    
    -- Slide-out animation
    function panel.animate_close()
        if panel.anim_status == "closing" then
            return
        end
        panel.anim_status = "closing"
        
        panel.outside_click_detector.visible = false
        
        local start_x = panel.box.x
        local end_x = panel.config.position == "right"
            and panel.box.screen.geometry.width
            or -panel.config.width
            
        local anim_steps = 20
        local step = 0
        local timer = gears.timer.start_new(0.005, function()
            step = step + 1
            panel.box.x = start_x + ((end_x - start_x) * (step / anim_steps))
            
            if step == anim_steps then
                panel.anim_status = "closed"
                panel.box.visible = false
                return false
            end
            
            return true
        end)
    end
end

-- Show the panel
function panel.show()
    if not panel.box.visible then
        panel.animate_open()
        panel.visible = true
    end
end

-- Hide the panel
function panel.hide()
    if panel.box.visible then
        panel.animate_close()
        panel.visible = false
    end
end

-- Toggle the panel
function panel.toggle()
    if panel.visible then
        panel.hide()
    else
        panel.show()
    end
end

return panel 