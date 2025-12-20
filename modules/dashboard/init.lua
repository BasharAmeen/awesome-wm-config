-- dashboard/init.lua
-- Main dashboard sidebar widget

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi

local calendar = require("modules.dashboard.calendar")
local stats = require("modules.dashboard.stats")

local dashboard = {}

-- Configuration
local SIDEBAR_WIDTH = dpi(280)

-- Colors
local bg_color = beautiful.bg_normal or "#1a1b26"
local border_color = beautiful.border_focus or "#7aa2f7"

-- State
local sidebar = nil
local visible = false

-- Create the sidebar
local function create_sidebar(s)
    -- Date/time widget
    local clock = wibox.widget {
        {
            {
                format = "%H:%M",
                font = "Sans Bold 32",
                align = "center",
                widget = wibox.widget.textclock,
            },
            {
                format = "%A, %B %d",
                font = "Sans 12",
                align = "center",
                widget = wibox.widget.textclock,
            },
            spacing = dpi(4),
            layout = wibox.layout.fixed.vertical,
        },
        margins = dpi(16),
        widget = wibox.container.margin,
    }
    
    -- User greeting
    local greeting = wibox.widget {
        {
            text = "👋 Hello, " .. os.getenv("USER"),
            font = "Sans Bold 14",
            align = "center",
            widget = wibox.widget.textbox,
        },
        margins = dpi(8),
        widget = wibox.container.margin,
    }
    
    -- Main content
    local content = wibox.widget {
        clock,
        greeting,
        {
            calendar.create(),
            margins = dpi(8),
            widget = wibox.container.margin,
        },
        {
            {
                stats.create(),
                bg = bg_color,
                shape = function(cr, w, h)
                    gears.shape.rounded_rect(cr, w, h, dpi(8))
                end,
                widget = wibox.container.background,
            },
            margins = dpi(8),
            widget = wibox.container.margin,
        },
        layout = wibox.layout.fixed.vertical,
    }
    
    -- Create sidebar wibox
    sidebar = wibox {
        visible = false,
        ontop = true,
        type = "dock",
        screen = s,
        width = SIDEBAR_WIDTH,
        height = s.geometry.height - dpi(40),
        x = s.geometry.x + s.geometry.width - SIDEBAR_WIDTH,
        y = s.geometry.y + dpi(35),
        bg = bg_color .. "F0",
        border_width = dpi(1),
        border_color = border_color,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(12))
        end,
    }
    
    sidebar:setup {
        content,
        margins = dpi(4),
        widget = wibox.container.margin,
    }
    
    -- Close when clicking outside
    sidebar:connect_signal("button::press", function(_, _, _, button)
        if button == 3 then
            dashboard.hide()
        end
    end)
    
    return sidebar
end

function dashboard.show()
    if not sidebar then
        sidebar = create_sidebar(awful.screen.focused())
    end
    sidebar.visible = true
    visible = true
end

function dashboard.hide()
    if sidebar then
        sidebar.visible = false
    end
    visible = false
end

function dashboard.toggle()
    if visible then
        dashboard.hide()
    else
        dashboard.show()
    end
end

return dashboard
