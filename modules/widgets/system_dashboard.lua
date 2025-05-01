local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local naughty = require("naughty")

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

-- Create a rounded container with consistent styling
local function create_widget_container(widget, width, height)
    local container = wibox.widget {
        {
            widget,
            id = "widget_container", -- Add an ID for easier targeting
            widget = wibox.container.margin,
            margins = dpi(10)
        },
        widget = wibox.container.background,
        forced_width = width or dpi(200),
        forced_height = height or dpi(120),
        bg = add_alpha(beautiful.bg_normal or "#222222", 0.7),
        shape = function(cr, w, h) 
            gears.shape.rounded_rect(cr, w, h, dpi(10))
        end
    }
    
    -- Add a subtle border
    container.border_width = dpi(1)
    container.border_color = add_alpha(beautiful.border_focus or "#535d6c", 0.5)
    
    return container
end

-- Base styling for progress bars
local function create_progressbar(color)
    local bar = wibox.widget {
        max_value        = 100,
        value            = 0,
        forced_height    = dpi(6),
        forced_width     = dpi(170),
        paddings         = dpi(1),
        shape            = gears.shape.rounded_bar,
        bar_shape        = gears.shape.rounded_bar,
        color            = color or add_alpha(beautiful.fg_normal or "#ffffff", 0.8),
        background_color = add_alpha(beautiful.bg_normal or "#000000", 0.3),
        border_width     = dpi(1),
        border_color     = add_alpha(beautiful.border_focus or "#535d6c", 0.5),
        widget           = wibox.widget.progressbar,
    }
    
    return bar
end

-- Dashboard structure
local system_dashboard = {}

-- CPU Widget
system_dashboard.cpu = {}
system_dashboard.cpu.icon = wibox.widget {
    markup = "<span foreground='#6fa8dc'>󰻠</span>", -- CPU icon
    font = "Nerd Font Mono 16",
    align = "center",
    widget = wibox.widget.textbox,
}

system_dashboard.cpu.title = wibox.widget {
    markup = "<span foreground='#ffffff'>CPU</span>",
    font = (beautiful.font or "sans") .. " 12",
    align = "left",
    widget = wibox.widget.textbox,
}

system_dashboard.cpu.usage = wibox.widget {
    markup = "<span foreground='#ffffff'>0%</span>",
    font = (beautiful.font or "sans") .. " 10",
    align = "right",
    widget = wibox.widget.textbox,
}

system_dashboard.cpu.cores = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>0 cores</span>",
    align = "left",
    widget = wibox.widget.textbox,
}

system_dashboard.cpu.temp = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>0°C</span>",
    align = "right",
    widget = wibox.widget.textbox,
}

system_dashboard.cpu.progressbar = create_progressbar("#6fa8dc") -- Blue

system_dashboard.cpu.widget = create_widget_container(
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(5),
        {
            layout = wibox.layout.align.horizontal,
            system_dashboard.cpu.icon,
            nil,
            system_dashboard.cpu.title,
        },
        {
            layout = wibox.layout.align.horizontal,
            system_dashboard.cpu.cores,
            nil,
            system_dashboard.cpu.temp,
        },
        system_dashboard.cpu.progressbar,
        {
            layout = wibox.layout.align.horizontal,
            nil,
            nil,
            system_dashboard.cpu.usage,
        },
    }
)

-- Memory Widget
system_dashboard.memory = {}
system_dashboard.memory.icon = wibox.widget {
    markup = "<span foreground='#76a5af'>󰍛</span>", -- Memory icon
    font = "Nerd Font Mono 16",
    align = "center",
    widget = wibox.widget.textbox,
}

system_dashboard.memory.title = wibox.widget {
    markup = "<span foreground='#ffffff'>Memory</span>",
    font = (beautiful.font or "sans") .. " 12",
    align = "left",
    widget = wibox.widget.textbox,
}

system_dashboard.memory.usage = wibox.widget {
    markup = "<span foreground='#ffffff'>0%</span>",
    font = (beautiful.font or "sans") .. " 10",
    align = "right",
    widget = wibox.widget.textbox,
}

system_dashboard.memory.used = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>0MB used</span>",
    align = "left",
    widget = wibox.widget.textbox,
}

system_dashboard.memory.total = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>0MB total</span>",
    align = "right",
    widget = wibox.widget.textbox,
}

system_dashboard.memory.progressbar = create_progressbar("#76a5af") -- Teal

-- Add swap usage to memory widget
system_dashboard.memory.swap_used = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>Swap: 0MB used</span>",
    align = "left",
    widget = wibox.widget.textbox,
}

system_dashboard.memory.swap_total = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>0MB total</span>",
    align = "right",
    widget = wibox.widget.textbox,
}

system_dashboard.memory.swap_progressbar = create_progressbar("#a2c4c9") -- Lighter teal for swap

system_dashboard.memory.widget = create_widget_container(
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(5),
        {
            layout = wibox.layout.align.horizontal,
            system_dashboard.memory.icon,
            nil,
            system_dashboard.memory.title,
        },
        {
            layout = wibox.layout.align.horizontal,
            system_dashboard.memory.used,
            nil,
            system_dashboard.memory.total,
        },
        system_dashboard.memory.progressbar,
        {
            layout = wibox.layout.align.horizontal,
            nil,
            nil,
            system_dashboard.memory.usage,
        },
        {
            layout = wibox.layout.align.horizontal,
            system_dashboard.memory.swap_used,
            nil,
            system_dashboard.memory.swap_total,
        },
        system_dashboard.memory.swap_progressbar,
    }
)

-- Disk Widget
system_dashboard.disk = {}
system_dashboard.disk.icon = wibox.widget {
    markup = "<span foreground='#b4a7d6'>󰋊</span>", -- Disk icon
    font = "Nerd Font Mono 16",
    align = "center",
    widget = wibox.widget.textbox,
}

system_dashboard.disk.title = wibox.widget {
    markup = "<span foreground='#ffffff'>Disk</span>",
    font = (beautiful.font or "sans") .. " 12",
    align = "left",
    widget = wibox.widget.textbox,
}

system_dashboard.disk.usage = wibox.widget {
    markup = "<span foreground='#ffffff'>0%</span>",
    font = (beautiful.font or "sans") .. " 10",
    align = "right",
    widget = wibox.widget.textbox,
}

system_dashboard.disk.used = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>0GB used</span>",
    align = "left",
    widget = wibox.widget.textbox,
}

system_dashboard.disk.total = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>0GB total</span>",
    align = "right",
    widget = wibox.widget.textbox,
}

system_dashboard.disk.progressbar = create_progressbar("#b4a7d6") -- Purple

system_dashboard.disk.widget = create_widget_container(
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(5),
        {
            layout = wibox.layout.align.horizontal,
            system_dashboard.disk.icon,
            nil,
            system_dashboard.disk.title,
        },
        {
            layout = wibox.layout.align.horizontal,
            system_dashboard.disk.used,
            nil,
            system_dashboard.disk.total,
        },
        system_dashboard.disk.progressbar,
        {
            layout = wibox.layout.align.horizontal,
            nil,
            nil,
            system_dashboard.disk.usage,
        },
    }
)

-- Network Widget
system_dashboard.network = {}
system_dashboard.network.icon = wibox.widget {
    markup = "<span foreground='#f6b26b'>󰤨</span>", -- Network icon
    font = "Nerd Font Mono 16",
    align = "center",
    widget = wibox.widget.textbox,
}

system_dashboard.network.title = wibox.widget {
    markup = "<span foreground='#ffffff'>Network</span>",
    font = (beautiful.font or "sans") .. " 12",
    align = "left",
    widget = wibox.widget.textbox,
}

system_dashboard.network.interface = wibox.widget {
    markup = "<span foreground='#ffffff'>None</span>",
    font = (beautiful.font or "sans") .. " 10",
    align = "right",
    widget = wibox.widget.textbox,
}

system_dashboard.network.download = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>↓ 0 KB/s</span>",
    align = "left",
    widget = wibox.widget.textbox,
}

system_dashboard.network.upload = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>↑ 0 KB/s</span>",
    align = "right",
    widget = wibox.widget.textbox,
}

-- Add connection type and signal strength
system_dashboard.network.connection_type = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>Type: Unknown</span>",
    align = "center",
    widget = wibox.widget.textbox,
}

system_dashboard.network.signal = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>Signal: N/A</span>",
    align = "center",
    widget = wibox.widget.textbox,
}

system_dashboard.network.transferred = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>TX: 0B | RX: 0B</span>",
    align = "center",
    widget = wibox.widget.textbox,
}

system_dashboard.network.widget = create_widget_container(
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(5),
        {
            layout = wibox.layout.align.horizontal,
            system_dashboard.network.icon,
            nil,
            system_dashboard.network.title,
        },
        {
            layout = wibox.layout.align.horizontal,
            nil,
            nil,
            system_dashboard.network.interface,
        },
        system_dashboard.network.connection_type,
        system_dashboard.network.signal,
        {
            layout = wibox.layout.align.horizontal,
            system_dashboard.network.download,
            nil,
            system_dashboard.network.upload,
        },
        system_dashboard.network.transferred
    },
    nil, -- Use default width
    dpi(180) -- Increased height to fit all information
)

-- Battery Widget
system_dashboard.battery = {}
system_dashboard.battery.icon = wibox.widget {
    markup = "<span foreground='#93c47d'>󰁹</span>", -- Battery icon
    font = "Nerd Font Mono 16",
    align = "center",
    widget = wibox.widget.textbox,
}

system_dashboard.battery.title = wibox.widget {
    markup = "<span foreground='#ffffff'>Battery</span>",
    font = (beautiful.font or "sans") .. " 12",
    align = "left",
    widget = wibox.widget.textbox,
}

system_dashboard.battery.status = wibox.widget {
    markup = "<span foreground='#ffffff'>N/A</span>",
    font = (beautiful.font or "sans") .. " 10",
    align = "right",
    widget = wibox.widget.textbox,
}

system_dashboard.battery.level = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>Level: N/A</span>",
    align = "left",
    widget = wibox.widget.textbox,
}

system_dashboard.battery.time = wibox.widget {
    markup = "<span size='small' foreground='#aaaaaa'>Time: N/A</span>",
    align = "right",
    widget = wibox.widget.textbox,
}

system_dashboard.battery.progressbar = create_progressbar("#93c47d") -- Green

system_dashboard.battery.widget = create_widget_container(
    {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(5),
        {
            layout = wibox.layout.align.horizontal,
            system_dashboard.battery.icon,
            nil,
            system_dashboard.battery.title,
        },
        {
            layout = wibox.layout.align.horizontal,
            system_dashboard.battery.level,
            nil,
            system_dashboard.battery.time,
        },
        system_dashboard.battery.progressbar,
        {
            layout = wibox.layout.align.horizontal,
            nil,
            nil,
            system_dashboard.battery.status,
        },
    }
)

-- Create uptime widget
function create_uptime_widget()
    local uptime = {}
    
    uptime.icon = wibox.widget {
        markup = "<span foreground='#8e7cc3'>󰅐</span>", -- Uptime icon
        font = "Nerd Font Mono 16",
        align = "center",
        widget = wibox.widget.textbox,
    }
    
    uptime.title = wibox.widget {
        markup = "<span foreground='#ffffff'>Uptime</span>",
        font = (beautiful.font or "sans") .. " 12",
        align = "left",
        widget = wibox.widget.textbox,
    }
    
    uptime.text = wibox.widget {
        markup = "<span foreground='#ffffff'>Loading...</span>",
        font = (beautiful.font or "sans") .. " 10",
        align = "center",
        widget = wibox.widget.textbox,
    }
    
    uptime.load = wibox.widget {
        markup = "<span size='small' foreground='#aaaaaa'>Load: 0.00 0.00 0.00</span>",
        align = "center",
        widget = wibox.widget.textbox,
    }
    
    -- Create the uptime widget
    uptime.widget = create_widget_container(
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(5),
            {
                layout = wibox.layout.align.horizontal,
                uptime.icon,
                nil,
                uptime.title,
            },
            uptime.text,
            uptime.load,
        }
    )
    
    -- Function to update uptime
    local function update_uptime()
        -- Get uptime
        awful.spawn.easy_async_with_shell(
            "uptime -p && uptime",
            function(stdout)
                local uptime_str = stdout:match("up%s+(.-)%s*load")
                local load1, load5, load15 = stdout:match("load average:%s+([%d%.]+),%s+([%d%.]+),%s+([%d%.]+)")
                
                if uptime_str then
                    uptime.text.markup = string.format(
                        "<span foreground='#ffffff'>%s</span>", uptime_str
                    )
                end
                
                if load1 and load5 and load15 then
                    uptime.load.markup = string.format(
                        "<span size='small' foreground='#aaaaaa'>Load: %s %s %s</span>", 
                        load1, load5, load15
                    )
                end
            end
        )
    end
    
    -- Update uptime initially and set timer
    update_uptime()
    gears.timer {
        timeout = 60,
        call_now = false,
        autostart = true,
        callback = function()
            if system_dashboard.popup.visible then
                update_uptime()
            end
        end
    }
    
    return uptime.widget
end

-- Create top processes widget
function create_top_processes_widget()
    local top = {}
    
    top.icon = wibox.widget {
        markup = "<span foreground='#cc4125'>󰘚</span>", -- Process icon
        font = "Nerd Font Mono 16",
        align = "center",
        widget = wibox.widget.textbox,
    }
    
    top.title = wibox.widget {
        markup = "<span foreground='#ffffff'>Top Processes</span>",
        font = (beautiful.font or "sans") .. " 12",
        align = "left",
        widget = wibox.widget.textbox,
    }
    
    -- Create the processes list
    top.list = wibox.widget {
        markup = "<span foreground='#aaaaaa'>Loading processes...</span>",
        font = (beautiful.font or "sans") .. " 9",
        align = "left",
        widget = wibox.widget.textbox,
    }
    
    -- Create the top processes widget
    top.widget = create_widget_container(
        {
            layout = wibox.layout.fixed.vertical,
            spacing = dpi(5),
            {
                layout = wibox.layout.align.horizontal,
                top.icon,
                nil,
                top.title,
            },
            top.list,
        }, 
        nil, -- Use default width
        dpi(150) -- Taller height for the process list
    )
    
    -- Function to update top processes
    local function update_top_processes()
        -- Get top processes
        awful.spawn.easy_async_with_shell(
            "ps -eo pmem,pcpu,comm --sort=-pcpu | head -n 6",
            function(stdout)
                local process_list = ""
                local lines = {}
                
                for line in stdout:gmatch("[^\r\n]+") do
                    table.insert(lines, line)
                end
                
                -- Skip the header line
                for i = 2, #lines do
                    local mem, cpu, cmd = lines[i]:match("([%d%.]+)%s+([%d%.]+)%s+(.+)")
                    if mem and cpu and cmd then
                        -- Truncate command if too long
                        if #cmd > 20 then
                            cmd = cmd:sub(1, 17) .. "..."
                        end
                        process_list = process_list .. string.format(
                            "<span foreground='#aaaaaa'>%s</span> <span foreground='#6fa8dc'>%s%%</span> <span foreground='#76a5af'>%s%%</span>\n",
                            cmd, cpu, mem
                        )
                    end
                end
                
                top.list.markup = process_list
            end
        )
    end
    
    -- Update processes initially and set timer
    update_top_processes()
    gears.timer {
        timeout = 5,
        call_now = false,
        autostart = true,
        callback = function()
            if system_dashboard.popup.visible then
                update_top_processes()
            end
        end
    }
    
    return top.widget
end

-- Create dashboard with all widgets
system_dashboard.dashboard = wibox.widget {
    layout = wibox.layout.fixed.vertical,
    spacing = dpi(10),
    {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(10),
        system_dashboard.cpu.widget,
        system_dashboard.memory.widget,
    },
    {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(10),
        system_dashboard.disk.widget,
        system_dashboard.network.widget,
    },
    {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(10),
        system_dashboard.battery.widget,
        create_uptime_widget(),
    },
    {
        layout = wibox.layout.flex.horizontal,
        spacing = dpi(10),
        create_top_processes_widget(),
    },
}

-- Create the dashboard popup
system_dashboard.popup = awful.popup {
    widget = wibox.widget {
        system_dashboard.dashboard,
        margins = dpi(20),
        widget = wibox.container.margin
    },
    ontop = true,
    visible = false,
    shape = function(cr, w, h) 
        gears.shape.rounded_rect(cr, w, h, dpi(12))
    end,
    bg = add_alpha(beautiful.bg_normal or "#222222", 0.85),
    placement = awful.placement.centered,
    border_width = dpi(1),
    border_color = add_alpha(beautiful.border_focus or "#535d6c", 0.7),
}

-- Add a close button to the dashboard
local close_button = wibox.widget {
    {
        {
            markup = "<span foreground='#ffffff'>✖</span>",
            font = (beautiful.font or "sans") .. " 12",
            align = "center",
            widget = wibox.widget.textbox,
        },
        margins = dpi(5),
        widget = wibox.container.margin
    },
    bg = add_alpha(beautiful.bg_urgent or "#ff0000", 0.5),
    shape = function(cr, w, h)
        gears.shape.circle(cr, w, h)
    end,
    widget = wibox.container.background
}

close_button:connect_signal("button::press", function()
    system_dashboard.popup.visible = false
end)

close_button:connect_signal("mouse::enter", function()
    close_button.bg = add_alpha(beautiful.bg_urgent or "#ff0000", 0.7)
end)

close_button:connect_signal("mouse::leave", function()
    close_button.bg = add_alpha(beautiful.bg_urgent or "#ff0000", 0.5)
end)

system_dashboard.popup:setup {
    {
        {
            layout = wibox.layout.align.horizontal,
            {
                markup = "<span foreground='#ffffff' font='" .. (beautiful.font or "sans") .. " 14'>System Dashboard</span>",
                widget = wibox.widget.textbox,
            },
            nil,
            close_button,
        },
        system_dashboard.dashboard,
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(10),
    },
    margins = dpi(20),
    widget = wibox.container.margin
}

-- Update functions
local function update_cpu()
    -- Get CPU usage
    awful.spawn.easy_async_with_shell(
        "grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}'",
        function(stdout)
            local cpu_usage = tonumber(stdout) or 0
            cpu_usage = math.floor(cpu_usage + 0.5)  -- Round to nearest integer
            
            system_dashboard.cpu.usage.markup = string.format(
                "<span foreground='#ffffff'>%d%%</span>", cpu_usage
            )
            
            system_dashboard.cpu.progressbar.value = cpu_usage
            
            -- Change color based on usage
            if cpu_usage > 80 then
                system_dashboard.cpu.progressbar.color = "#e06c75"  -- Red
            elseif cpu_usage > 50 then
                system_dashboard.cpu.progressbar.color = "#e5c07b"  -- Yellow
            else
                system_dashboard.cpu.progressbar.color = "#6fa8dc"  -- Blue
            end
        end
    )
    
    -- Get CPU cores
    awful.spawn.easy_async_with_shell(
        "nproc",
        function(stdout)
            local cores = tonumber(stdout) or 0
            system_dashboard.cpu.cores.markup = string.format(
                "<span size='small' foreground='#aaaaaa'>%d cores</span>", cores
            )
        end
    )
    
    -- Get CPU temperature
    awful.spawn.easy_async_with_shell(
        "cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | head -1",
        function(stdout)
            local temp = tonumber(stdout) or 0
            if temp > 1000 then
                temp = temp / 1000  -- Convert from millidegrees to degrees
            end
            
            system_dashboard.cpu.temp.markup = string.format(
                "<span size='small' foreground='#aaaaaa'>%.1f°C</span>", temp
            )
        end
    )
    
    -- Get CPU frequency
    awful.spawn.easy_async_with_shell(
        "cat /proc/cpuinfo | grep 'MHz' | head -1 | awk '{print $4}'",
        function(stdout)
            local freq = tonumber(stdout) or 0
            
            -- Add frequency information if not already added
            if not system_dashboard.cpu.freq then
                system_dashboard.cpu.freq = wibox.widget {
                    markup = string.format("<span size='small' foreground='#aaaaaa'>%.1f GHz</span>", freq/1000),
                    align = "center",
                    widget = wibox.widget.textbox,
                }
                
                -- Add the frequency widget to the CPU widget
                local cpu_widget_content = system_dashboard.cpu.widget:get_children_by_id("widget_container")[1]
                if cpu_widget_content then
                    local layout = wibox.widget {
                        layout = wibox.layout.align.horizontal,
                        system_dashboard.cpu.cores,
                        system_dashboard.cpu.freq,
                        system_dashboard.cpu.temp,
                    }
                    
                    -- Replace the existing cores/temp row with our new layout
                    for i, child in ipairs(cpu_widget_content:get_children()) do
                        if child:get_children()[1] == system_dashboard.cpu.cores then
                            cpu_widget_content:replace_widget(child, layout)
                            break
                        end
                    end
                end
            else
                system_dashboard.cpu.freq.markup = string.format(
                    "<span size='small' foreground='#aaaaaa'>%.1f GHz</span>", freq/1000
                )
            end
        end
    )
end

local function update_memory()
    -- Get memory usage
    awful.spawn.easy_async_with_shell(
        "free -m | grep 'Mem:' | awk '{print $3, $2, $3/$2 * 100.0}'",
        function(stdout)
            local used, total, usage = stdout:match("(%d+)%s+(%d+)%s+(%d+%.?%d*)")
            
            used = tonumber(used) or 0
            total = tonumber(total) or 1
            usage = tonumber(usage) or 0
            usage = math.floor(usage + 0.5)  -- Round to nearest integer
            
            -- Format used memory
            local used_str
            if used < 1024 then
                used_str = string.format("%d MB", used)
            else
                used_str = string.format("%.1f GB", used / 1024)
            end
            
            -- Format total memory
            local total_str
            if total < 1024 then
                total_str = string.format("%d MB", total)
            else
                total_str = string.format("%.1f GB", total / 1024)
            end
            
            system_dashboard.memory.used.markup = string.format(
                "<span size='small' foreground='#aaaaaa'>%s used</span>", used_str
            )
            
            system_dashboard.memory.total.markup = string.format(
                "<span size='small' foreground='#aaaaaa'>%s total</span>", total_str
            )
            
            system_dashboard.memory.usage.markup = string.format(
                "<span foreground='#ffffff'>%d%%</span>", usage
            )
            
            system_dashboard.memory.progressbar.value = usage
            
            -- Change color based on usage
            if usage > 80 then
                system_dashboard.memory.progressbar.color = "#e06c75"  -- Red
            elseif usage > 50 then
                system_dashboard.memory.progressbar.color = "#e5c07b"  -- Yellow
            else
                system_dashboard.memory.progressbar.color = "#76a5af"  -- Teal
            end
        end
    )
    
    -- Get swap usage
    awful.spawn.easy_async_with_shell(
        "free -m | grep 'Swap:' | awk '{print $3, $2, $3/$2 * 100.0}'",
        function(stdout)
            local used, total, usage = stdout:match("(%d+)%s+(%d+)%s+(%d+%.?%d*)")
            
            used = tonumber(used) or 0
            total = tonumber(total) or 1
            
            -- If there's no swap or it's not being used, handle that case
            if total == 0 then
                system_dashboard.memory.swap_used.markup = "<span size='small' foreground='#aaaaaa'>No swap available</span>"
                system_dashboard.memory.swap_total.markup = ""
                system_dashboard.memory.swap_progressbar.value = 0
                return
            end
            
            usage = tonumber(usage) or 0
            usage = math.floor(usage + 0.5)  -- Round to nearest integer
            
            -- Format used swap
            local used_str
            if used < 1024 then
                used_str = string.format("%d MB", used)
            else
                used_str = string.format("%.1f GB", used / 1024)
            end
            
            -- Format total swap
            local total_str
            if total < 1024 then
                total_str = string.format("%d MB", total)
            else
                total_str = string.format("%.1f GB", total / 1024)
            end
            
            system_dashboard.memory.swap_used.markup = string.format(
                "<span size='small' foreground='#aaaaaa'>Swap: %s used</span>", used_str
            )
            
            system_dashboard.memory.swap_total.markup = string.format(
                "<span size='small' foreground='#aaaaaa'>%s total</span>", total_str
            )
            
            system_dashboard.memory.swap_progressbar.value = usage
            
            -- Change color based on usage
            if usage > 80 then
                system_dashboard.memory.swap_progressbar.color = "#e06c75"  -- Red
            elseif usage > 50 then
                system_dashboard.memory.swap_progressbar.color = "#e5c07b"  -- Yellow
            else
                system_dashboard.memory.swap_progressbar.color = "#a2c4c9"  -- Light teal
            end
        end
    )
end

local function update_disk()
    -- Get disk usage for root partition
    awful.spawn.easy_async_with_shell(
        "df -h / | tail -1 | awk '{print $3, $2, $5}'",
        function(stdout)
            local used, total, usage = stdout:match("(%S+)%s+(%S+)%s+(%d+)%%")
            
            used = used or "0G"
            total = total or "0G"
            usage = tonumber(usage) or 0
            
            system_dashboard.disk.used.markup = string.format(
                "<span size='small' foreground='#aaaaaa'>%s used</span>", used
            )
            
            system_dashboard.disk.total.markup = string.format(
                "<span size='small' foreground='#aaaaaa'>%s total</span>", total
            )
            
            system_dashboard.disk.usage.markup = string.format(
                "<span foreground='#ffffff'>%d%%</span>", usage
            )
            
            system_dashboard.disk.progressbar.value = usage
            
            -- Change color based on usage
            if usage > 90 then
                system_dashboard.disk.progressbar.color = "#e06c75"  -- Red
            elseif usage > 70 then
                system_dashboard.disk.progressbar.color = "#e5c07b"  -- Yellow
            else
                system_dashboard.disk.progressbar.color = "#b4a7d6"  -- Purple
            end
        end
    )
    
    -- Get disk I/O
    awful.spawn.easy_async_with_shell(
        "cat /proc/diskstats | grep 'sd[a-z] ' | head -1 | awk '{print $6, $10}'",
        function(stdout)
            local reads, writes = stdout:match("(%d+)%s+(%d+)")
            
            reads = tonumber(reads) or 0
            writes = tonumber(writes) or 0
            
            -- Add I/O information if not already added
            if not system_dashboard.disk.io then
                system_dashboard.disk.io = wibox.widget {
                    markup = string.format("<span size='small' foreground='#aaaaaa'>I/O: %dR/%dW</span>", reads, writes),
                    align = "center",
                    widget = wibox.widget.textbox,
                }
                
                -- Add the I/O widget to the disk widget
                local disk_widget_content = system_dashboard.disk.widget:get_children_by_id("widget_container")[1]
                if disk_widget_content then
                    -- Add after the progressbar
                    local layout = wibox.widget {
                        layout = wibox.layout.align.horizontal,
                        nil,
                        system_dashboard.disk.io,
                        nil,
                    }
                    
                    -- Insert after progressbar
                    for i, child in ipairs(disk_widget_content:get_children()) do
                        if child == system_dashboard.disk.progressbar then
                            table.insert(disk_widget_content:get_children(), i+1, layout)
                            break
                        end
                    end
                end
            else
                system_dashboard.disk.io.markup = string.format(
                    "<span size='small' foreground='#aaaaaa'>I/O: %dR/%dW</span>", reads, writes
                )
            end
        end
    )
end

-- Variables to store previous network stats
local prev_rx = 0
local prev_tx = 0
local prev_time = 0

local function format_speed(bytes_per_sec)
    if bytes_per_sec < 1024 then
        return string.format("%d B/s", bytes_per_sec)
    elseif bytes_per_sec < 1024 * 1024 then
        return string.format("%.1f KB/s", bytes_per_sec / 1024)
    else
        return string.format("%.1f MB/s", bytes_per_sec / (1024 * 1024))
    end
end

local function update_network()
    -- Check for active network interface
    awful.spawn.easy_async_with_shell(
        "ip route get 1.1.1.1 2>/dev/null | head -1 | awk '{print $5}'",
        function(iface)
            local interface = iface:gsub("%s+", "")
            
            if interface == "" then
                -- No active interface
                system_dashboard.network.interface.markup = "<span foreground='#ffffff'>Not connected</span>"
                system_dashboard.network.download.markup = "<span size='small' foreground='#aaaaaa'>↓ 0 KB/s</span>"
                system_dashboard.network.upload.markup = "<span size='small' foreground='#aaaaaa'>↑ 0 KB/s</span>"
                
                -- Update IP if we've added it
                if system_dashboard.network.ip then
                    system_dashboard.network.ip.markup = "<span size='small' foreground='#aaaaaa'>IP: None</span>"
                end
                
                system_dashboard.network.connection_type.markup = "<span size='small' foreground='#aaaaaa'>Type: Not connected</span>"
                system_dashboard.network.signal.markup = "<span size='small' foreground='#aaaaaa'>Signal: N/A</span>"
                system_dashboard.network.transferred.markup = "<span size='small' foreground='#aaaaaa'>TX: 0B | RX: 0B</span>"
                
                return
            end
            
            system_dashboard.network.interface.markup = string.format(
                "<span foreground='#ffffff'>%s</span>", interface
            )
            
            -- Get IP address
            awful.spawn.easy_async_with_shell(
                string.format("ip addr show %s | grep 'inet ' | awk '{print $2}' | cut -d/ -f1", interface),
                function(ip_stdout)
                    local ip = ip_stdout:gsub("%s+", "")
                    
                    -- Add IP information if not already added
                    if not system_dashboard.network.ip then
                        system_dashboard.network.ip = wibox.widget {
                            markup = string.format("<span size='small' foreground='#aaaaaa'>IP: %s</span>", ip),
                            align = "center",
                            widget = wibox.widget.textbox,
                        }
                        
                        -- Add the IP widget to the network widget
                        local network_widget_content = system_dashboard.network.widget:get_children_by_id("widget_container")[1]
                        if network_widget_content then
                            -- Create a new layout with the IP address
                            local layout = wibox.widget {
                                layout = wibox.layout.align.horizontal,
                                nil,
                                system_dashboard.network.ip,
                                nil,
                            }
                            
                            -- Insert after interface name
                            for i, child in ipairs(network_widget_content:get_children()) do
                                if child:get_children()[3] == system_dashboard.network.interface then
                                    table.insert(network_widget_content:get_children(), i+1, layout)
                                    break
                                end
                            end
                        end
                    else
                        system_dashboard.network.ip.markup = string.format(
                            "<span size='small' foreground='#aaaaaa'>IP: %s</span>", ip
                        )
                    end
                    
                    -- Check if it's a wireless interface and get SSID
                    awful.spawn.easy_async_with_shell(
                        string.format("iwconfig %s 2>/dev/null | grep ESSID | cut -d: -f2", interface),
                        function(ssid_stdout)
                            local ssid = ssid_stdout:gsub("[%s\"]+", "")
                            
                            if ssid ~= "" then
                                -- Add SSID information if not already added
                                if not system_dashboard.network.ssid then
                                    system_dashboard.network.ssid = wibox.widget {
                                        markup = string.format("<span size='small' foreground='#aaaaaa'>SSID: %s</span>", ssid),
                                        align = "center",
                                        widget = wibox.widget.textbox,
                                    }
                                    
                                    -- Add the SSID widget to the network widget
                                    local network_widget_content = system_dashboard.network.widget:get_children_by_id("widget_container")[1]
                                    if network_widget_content then
                                        -- Create a new layout with the SSID
                                        local layout = wibox.widget {
                                            layout = wibox.layout.align.horizontal,
                                            nil,
                                            system_dashboard.network.ssid,
                                            nil,
                                        }
                                        
                                        -- Insert after IP
                                        for i, child in ipairs(network_widget_content:get_children()) do
                                            if system_dashboard.network.ip and child:get_children()[2] == system_dashboard.network.ip then
                                                table.insert(network_widget_content:get_children(), i+1, layout)
                                                break
                                            end
                                        end
                                    end
                                else
                                    system_dashboard.network.ssid.markup = string.format(
                                        "<span size='small' foreground='#aaaaaa'>SSID: %s</span>", ssid
                                    )
                                end
                            end
                        end
                    )
                end
            )
            
            -- Determine connection type (wired/wireless)
            awful.spawn.easy_async_with_shell(
                string.format("[ -d /sys/class/net/%s/wireless ] && echo wireless || echo wired", interface),
                function(conn_type)
                    local connection_type = conn_type:gsub("%s+", "")
                    system_dashboard.network.connection_type.markup = string.format(
                        "<span size='small' foreground='#aaaaaa'>Type: %s</span>", 
                        connection_type:gsub("^%l", string.upper) -- Capitalize first letter
                    )
                    
                    -- If wireless, get signal strength
                    if connection_type == "wireless" then
                        awful.spawn.easy_async_with_shell(
                            string.format("iwconfig %s 2>/dev/null | grep 'Link Quality' | awk -F= '{print $2}' | awk '{print $1}'", interface),
                            function(quality_stdout)
                                local quality = quality_stdout:gsub("%s+", "")
                                local current, max = quality:match("(%d+)/(%d+)")
                                
                                if current and max then
                                    local signal_percent = math.floor((tonumber(current) / tonumber(max)) * 100 + 0.5)
                                    system_dashboard.network.signal.markup = string.format(
                                        "<span size='small' foreground='#aaaaaa'>Signal: %d%%</span>", signal_percent
                                    )
                                else
                                    system_dashboard.network.signal.markup = "<span size='small' foreground='#aaaaaa'>Signal: Unknown</span>"
                                end
                            end
                        )
                    else
                        system_dashboard.network.signal.markup = "<span size='small' foreground='#aaaaaa'>Signal: N/A (wired)</span>"
                    end
                end
            )
            
            -- Get network traffic for this interface
            awful.spawn.easy_async_with_shell(
                string.format("cat /proc/net/dev | grep %s | awk '{print $2, $10}'", interface),
                function(stdout)
                    local rx, tx = stdout:match("(%d+)%s+(%d+)")
                    
                    rx = tonumber(rx) or 0
                    tx = tonumber(tx) or 0
                    
                    local now = os.time()
                    local time_diff = now - prev_time
                    
                    if prev_rx > 0 and prev_tx > 0 and time_diff > 0 then
                        local rx_speed = (rx - prev_rx) / time_diff
                        local tx_speed = (tx - prev_tx) / time_diff
                        
                        system_dashboard.network.download.markup = string.format(
                            "<span size='small' foreground='#aaaaaa'>↓ %s</span>", format_speed(rx_speed)
                        )
                        
                        system_dashboard.network.upload.markup = string.format(
                            "<span size='small' foreground='#aaaaaa'>↑ %s</span>", format_speed(tx_speed)
                        )
                    end
                    
                    prev_rx = rx
                    prev_tx = tx
                    prev_time = now
                end
            )
        end
    )
end

local function update_battery()
    -- Check if battery exists
    awful.spawn.easy_async_with_shell("ls /sys/class/power_supply/BAT* 2>/dev/null", function(stdout)
        if stdout == "" then
            -- No battery found
            system_dashboard.battery.title.markup = "<span foreground='#ffffff'>No Battery</span>"
            system_dashboard.battery.icon.markup = "<span foreground='#aaaaaa'>󱉝</span>"
            system_dashboard.battery.level.markup = "<span size='small' foreground='#aaaaaa'>Level: N/A</span>"
            system_dashboard.battery.time.markup = "<span size='small' foreground='#aaaaaa'>Time: N/A</span>"
            system_dashboard.battery.status.markup = "<span foreground='#ffffff'>N/A</span>"
            system_dashboard.battery.progressbar.value = 0
            return
        end
        
        -- Battery exists, get details
        awful.spawn.easy_async_with_shell("cat /sys/class/power_supply/BAT*/capacity", function(capacity)
            local level = tonumber(capacity) or 0
            
            awful.spawn.easy_async_with_shell("cat /sys/class/power_supply/BAT*/status", function(status)
                local charging = status:match("Charging") ~= nil
                local full = status:match("Full") ~= nil
                
                -- Update icon based on level and charging status
                local icon_color = "#93c47d"  -- Green by default
                local icon_markup = "<span foreground='" .. icon_color .. "'>󰁹</span>"
                
                if charging then
                    icon_markup = "<span foreground='" .. icon_color .. "'>󰂄</span>"
                elseif full then
                    icon_markup = "<span foreground='" .. icon_color .. "'>󰁹</span>"
                else
                    if level < 10 then
                        icon_color = "#e06c75"  -- Red
                        icon_markup = "<span foreground='" .. icon_color .. "'>󰁺</span>"
                    elseif level < 30 then
                        icon_color = "#e5c07b"  -- Yellow
                        icon_markup = "<span foreground='" .. icon_color .. "'>󰁻</span>"
                    elseif level < 60 then
                        icon_markup = "<span foreground='" .. icon_color .. "'>󰁽</span>"
                    elseif level < 90 then
                        icon_markup = "<span foreground='" .. icon_color .. "'>󰁾</span>"
                    end
                end
                
                system_dashboard.battery.icon.markup = icon_markup
                
                -- Update status text
                local status_text
                if charging then
                    status_text = "Charging"
                elseif full then
                    status_text = "Full"
                else
                    status_text = "Discharging"
                end
                
                system_dashboard.battery.status.markup = string.format(
                    "<span foreground='#ffffff'>%s</span>", status_text
                )
                
                -- Update level
                system_dashboard.battery.level.markup = string.format(
                    "<span size='small' foreground='#aaaaaa'>Level: %d%%</span>", level
                )
                
                -- Update progressbar
                system_dashboard.battery.progressbar.value = level
                
                -- Change color based on level
                if level < 20 and not charging then
                    system_dashboard.battery.progressbar.color = "#e06c75"  -- Red
                elseif level < 40 and not charging then
                    system_dashboard.battery.progressbar.color = "#e5c07b"  -- Yellow
                else
                    system_dashboard.battery.progressbar.color = "#93c47d"  -- Green
                end
                
                -- Get time remaining if available
                awful.spawn.easy_async_with_shell(
                    "upower -i $(upower -e | grep BAT) | grep 'time to' | awk '{print $4, $5}'",
                    function(time_stdout)
                        local time_value, time_unit = time_stdout:match("(%d+%.?%d*)%s+(%w+)")
                        
                        if time_value and time_unit then
                            system_dashboard.battery.time.markup = string.format(
                                "<span size='small' foreground='#aaaaaa'>Time: %s %s</span>", time_value, time_unit
                            )
                        else
                            system_dashboard.battery.time.markup = "<span size='small' foreground='#aaaaaa'>Time: N/A</span>"
                        end
                    end
                )
            end)
        end)
    end)
end

-- Call the update icon fonts function when initialized
-- update_icon_fonts()

-- Function to toggle dashboard visibility
function system_dashboard.toggle()
    if system_dashboard.popup.visible then
        system_dashboard.popup.visible = false
    else
        -- Update all widgets before showing
        update_cpu()
        update_memory()
        update_disk()
        update_network()
        update_battery()
        
        -- Show the dashboard
        system_dashboard.popup.visible = true
    end
end

-- Update all widgets periodically
gears.timer {
    timeout = 2,
    call_now = true,
    autostart = true,
    callback = function()
        if system_dashboard.popup.visible then
            update_cpu()
            update_memory()
            update_disk()
            update_network()
            update_battery()
        end
    end
}

-- Make sure nerd font is installed if not already
gears.timer.start_new(1, function()
    awful.spawn.easy_async_with_shell("fc-list | grep -i 'nerd'", function(stdout)
        if stdout == "" then
            -- Nerd Font not found, notify user and attempt to install
            naughty.notify({
                title = "System Dashboard",
                text = "Nerd Font not detected. Trying to run font install script...",
                timeout = 10
            })
            
            -- Try to run the install script
            awful.spawn.with_shell("~/.config/awesome/install_nerdfonts.sh")
        end
    end)
    return false  -- Don't repeat the timer
end)

return system_dashboard 