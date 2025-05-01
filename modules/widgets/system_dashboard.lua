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
    font = "FontAwesome 18",
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
    font = "FontAwesome 18",
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
    }
)

-- Disk Widget
system_dashboard.disk = {}
system_dashboard.disk.icon = wibox.widget {
    markup = "<span foreground='#b4a7d6'>󰋊</span>", -- Disk icon
    font = "FontAwesome 18",
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
    font = "FontAwesome 18",
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
        {
            layout = wibox.layout.align.horizontal,
            system_dashboard.network.download,
            nil,
            system_dashboard.network.upload,
        },
    }
)

-- Battery Widget
system_dashboard.battery = {}
system_dashboard.battery.icon = wibox.widget {
    markup = "<span foreground='#93c47d'>󰁹</span>", -- Battery icon
    font = "FontAwesome 18",
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
                return
            end
            
            system_dashboard.network.interface.markup = string.format(
                "<span foreground='#ffffff'>%s</span>", interface
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

return system_dashboard 