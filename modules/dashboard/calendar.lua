-- dashboard/calendar.lua
-- Calendar widget component

local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi

local calendar_widget = {}

-- Colors
local bg_color = beautiful.bg_normal or "#1a1b26"
local fg_color = beautiful.fg_normal or "#c0caf5"
local accent_color = "#7aa2f7"
local dim_color = "#565f89"

-- Get calendar data
local function get_calendar_data()
    local now = os.date("*t")
    local first_day = os.time({year = now.year, month = now.month, day = 1})
    local first_weekday = os.date("*t", first_day).wday  -- 1=Sunday
    
    -- Get days in month
    local days_in_month
    if now.month == 12 then
        days_in_month = 31
    else
        local next_month = os.time({year = now.year, month = now.month + 1, day = 1})
        days_in_month = os.date("*t", next_month - 86400).day
    end
    
    return {
        year = now.year,
        month = now.month,
        day = now.day,
        first_weekday = first_weekday,
        days_in_month = days_in_month,
    }
end

-- Create day cell
local function create_day_cell(day, is_today, is_current_month)
    local fg = is_current_month and fg_color or dim_color
    local bg = is_today and accent_color or "transparent"
    local text_fg = is_today and "#ffffff" or fg
    
    return wibox.widget {
        {
            {
                text = day and tostring(day) or "",
                font = "Sans 10",
                align = "center",
                widget = wibox.widget.textbox,
            },
            margins = dpi(4),
            widget = wibox.container.margin,
        },
        bg = bg,
        fg = text_fg,
        shape = gears.shape.circle,
        forced_width = dpi(28),
        forced_height = dpi(28),
        widget = wibox.container.background,
    }
end

function calendar_widget.create()
    local data = get_calendar_data()
    local months = {"January", "February", "March", "April", "May", "June",
                    "July", "August", "September", "October", "November", "December"}
    local days = {"Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"}
    
    -- Header with month/year
    local header = wibox.widget {
        {
            text = months[data.month] .. " " .. data.year,
            font = "Sans Bold 12",
            align = "center",
            widget = wibox.widget.textbox,
        },
        margins = dpi(8),
        widget = wibox.container.margin,
    }
    
    -- Day names row
    local day_names = wibox.widget {
        layout = wibox.layout.flex.horizontal,
    }
    for _, d in ipairs(days) do
        day_names:add(wibox.widget {
            {
                text = d,
                font = "Sans Bold 9",
                align = "center",
                widget = wibox.widget.textbox,
            },
            fg = dim_color,
            widget = wibox.container.background,
        })
    end
    
    -- Calendar grid
    local grid = wibox.widget {
        layout = wibox.layout.grid,
        forced_num_cols = 7,
        spacing = dpi(2),
        homogeneous = true,
    }
    
    -- Add empty cells for days before month starts
    for i = 1, data.first_weekday - 1 do
        grid:add(create_day_cell(nil, false, false))
    end
    
    -- Add days
    for day = 1, data.days_in_month do
        local is_today = (day == data.day)
        grid:add(create_day_cell(day, is_today, true))
    end
    
    return wibox.widget {
        {
            header,
            {
                day_names,
                margins = dpi(4),
                widget = wibox.container.margin,
            },
            {
                grid,
                margins = dpi(4),
                widget = wibox.container.margin,
            },
            layout = wibox.layout.fixed.vertical,
        },
        bg = bg_color,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(8))
        end,
        widget = wibox.container.background,
    }
end

return calendar_widget
