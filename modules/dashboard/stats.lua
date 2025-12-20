-- dashboard/stats.lua
-- System stats widget component

local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local awful = require("awful")

local stats_widget = {}

-- Colors
local bg_color = beautiful.bg_normal or "#1a1b26"
local fg_color = beautiful.fg_normal or "#c0caf5"
local accent_color = "#7aa2f7"
local cpu_color = "#f7768e"
local mem_color = "#9ece6a"
local disk_color = "#e0af68"

-- Create progress bar
local function create_stat_bar(label, color, initial_value)
    local bar = wibox.widget {
        max_value = 100,
        value = initial_value or 0,
        forced_height = dpi(8),
        color = color,
        background_color = "#414868",
        shape = gears.shape.rounded_bar,
        widget = wibox.widget.progressbar,
    }
    
    local value_text = wibox.widget {
        text = "0%",
        font = "Sans 10",
        align = "right",
        widget = wibox.widget.textbox,
    }
    
    return wibox.widget {
        {
            {
                text = label,
                font = "Sans Bold 10",
                widget = wibox.widget.textbox,
            },
            nil,
            value_text,
            layout = wibox.layout.align.horizontal,
        },
        bar,
        spacing = dpi(4),
        layout = wibox.layout.fixed.vertical,
    }, bar, value_text
end

-- Get CPU usage
local function get_cpu_usage(callback)
    awful.spawn.easy_async_with_shell(
        "top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}'",
        function(stdout)
            local cpu = tonumber(stdout) or 0
            callback(math.floor(cpu))
        end
    )
end

-- Get memory usage
local function get_mem_usage(callback)
    awful.spawn.easy_async_with_shell(
        "free | awk '/Mem:/ {printf \"%.0f\", $3/$2 * 100}'",
        function(stdout)
            local mem = tonumber(stdout) or 0
            callback(mem)
        end
    )
end

-- Get disk usage
local function get_disk_usage(callback)
    awful.spawn.easy_async_with_shell(
        "df / | awk 'NR==2 {print $5}' | tr -d '%'",
        function(stdout)
            local disk = tonumber(stdout) or 0
            callback(disk)
        end
    )
end

-- Get uptime
local function get_uptime(callback)
    awful.spawn.easy_async_with_shell(
        "uptime -p | sed 's/up //'",
        function(stdout)
            callback(stdout:gsub("\n", ""))
        end
    )
end

function stats_widget.create()
    local cpu_widget, cpu_bar, cpu_text = create_stat_bar("CPU", cpu_color, 0)
    local mem_widget, mem_bar, mem_text = create_stat_bar("Memory", mem_color, 0)
    local disk_widget, disk_bar, disk_text = create_stat_bar("Disk", disk_color, 0)
    
    local uptime_text = wibox.widget {
        text = "...",
        font = "Sans 10",
        align = "center",
        widget = wibox.widget.textbox,
    }
    
    -- Update function
    local function update_stats()
        get_cpu_usage(function(val)
            cpu_bar.value = val
            cpu_text.text = val .. "%"
        end)
        get_mem_usage(function(val)
            mem_bar.value = val
            mem_text.text = val .. "%"
        end)
        get_disk_usage(function(val)
            disk_bar.value = val
            disk_text.text = val .. "%"
        end)
        get_uptime(function(val)
            uptime_text.text = "⏱ " .. val
        end)
    end
    
    -- Initial update
    update_stats()
    
    -- Update every 5 seconds
    gears.timer {
        timeout = 5,
        autostart = true,
        callback = update_stats,
    }
    
    return wibox.widget {
        {
            {
                text = "System Stats",
                font = "Sans Bold 12",
                align = "center",
                widget = wibox.widget.textbox,
            },
            {
                cpu_widget,
                mem_widget,
                disk_widget,
                spacing = dpi(12),
                layout = wibox.layout.fixed.vertical,
            },
            {
                uptime_text,
                top = dpi(8),
                widget = wibox.container.margin,
            },
            spacing = dpi(8),
            layout = wibox.layout.fixed.vertical,
        },
        margins = dpi(12),
        widget = wibox.container.margin,
    }
end

return stats_widget
