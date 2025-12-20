-- notification_center/widget.lua
-- Popup widget for browsing notification history

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local gfs = require("gears.filesystem")

local widget = {}

-- Configuration
local WIDGET_WIDTH = dpi(380)
local MAX_VISIBLE_ITEMS = 6
local ITEM_HEIGHT = dpi(65)
local DATA_DIR = gfs.get_configuration_dir() .. "data/notifications/"

-- State
local popup = nil
local notifications_list = nil
local current_filter = "all"

-- Colors (with fallbacks)
local bg_color = beautiful.bg_normal or "#1a1b26"
local fg_color = beautiful.fg_normal or "#c0caf5"
local bg_focus = beautiful.bg_focus or "#414868"
local border_color = beautiful.border_focus or "#7aa2f7"
local accent_color = "#7aa2f7"
local urgent_color = "#f7768e"

-- Load history module
local history = nil
local function get_history()
    if not history then
        history = require("modules.notification_center.history")
    end
    return history
end

-- Safe shell escape function
local function shell_escape(s)
    if not s then return "" end
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Format timestamp for display
local function format_time(timestamp)
    if not timestamp then return "" end
    
    local y, m, d, h, min = timestamp:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
    if not y then return timestamp end
    
    local now = os.date("*t")
    
    if tonumber(y) == now.year and tonumber(m) == now.month and tonumber(d) == now.day then
        return h .. ":" .. min
    end
    
    local yesterday = os.date("*t", os.time() - 86400)
    if tonumber(y) == yesterday.year and tonumber(m) == yesterday.month and tonumber(d) == yesterday.day then
        return "Yesterday"
    end
    
    return d .. "/" .. m
end

-- Create a notification item widget
local function create_notification_item(n)
    -- App icon (letter avatar)
    local app_initial = (n.app_name or "?"):sub(1, 1):upper()
    local icon_widget = wibox.widget {
        {
            text = app_initial,
            font = "Sans Bold 14",
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox,
        },
        bg = accent_color,
        fg = "#ffffff",
        shape = gears.shape.circle,
        forced_width = dpi(36),
        forced_height = dpi(36),
        widget = wibox.container.background,
    }
    
    local item = wibox.widget {
        {
            {
                -- Icon
                {
                    icon_widget,
                    margins = dpi(8),
                    widget = wibox.container.margin,
                },
                -- Content
                {
                    {
                        -- Top row: app name + time
                        {
                            {
                                text = n.app_name or "Unknown",
                                font = "Sans Bold 10",
                                widget = wibox.widget.textbox,
                            },
                            nil,
                            {
                                text = format_time(n.timestamp),
                                font = "Sans 9",
                                widget = wibox.widget.textbox,
                            },
                            layout = wibox.layout.align.horizontal,
                        },
                        -- Title
                        {
                            text = n.title or "",
                            font = "Sans Bold 11",
                            ellipsize = "end",
                            widget = wibox.widget.textbox,
                        },
                        -- Message
                        {
                            text = (n.text or ""):sub(1, 60):gsub("\n", " "),
                            font = "Sans 9",
                            ellipsize = "end",
                            widget = wibox.widget.textbox,
                        },
                        layout = wibox.layout.fixed.vertical,
                        spacing = dpi(1),
                    },
                    margins = dpi(4),
                    widget = wibox.container.margin,
                },
                layout = wibox.layout.fixed.horizontal,
            },
            margins = dpi(4),
            widget = wibox.container.margin,
        },
        bg = bg_color,
        fg = fg_color,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(8))
        end,
        widget = wibox.container.background,
        forced_height = ITEM_HEIGHT,
    }
    
    -- Hover effect
    item:connect_signal("mouse::enter", function(self)
        self.bg = bg_focus
    end)
    
    item:connect_signal("mouse::leave", function(self)
        self.bg = bg_color
    end)
    
    -- Click handlers
    item:buttons(gears.table.join(
        awful.button({}, 1, function()
            -- Left click: Copy to clipboard
            local text = (n.title or "") .. "\n" .. (n.text or "")
            awful.spawn.with_shell("echo " .. shell_escape(text) .. " | xclip -selection clipboard 2>/dev/null")
            awful.spawn.with_shell("notify-send 'Copied' 'Notification copied to clipboard'")
        end),
        awful.button({}, 3, function()
            -- Right click: Show context menu
            local menu = awful.menu({
                items = {
                    { "Copy", function()
                        local text = (n.title or "") .. "\n" .. (n.text or "")
                        awful.spawn.with_shell("echo " .. shell_escape(text) .. " | xclip -selection clipboard 2>/dev/null")
                        awful.spawn.with_shell("notify-send 'Copied' 'Notification copied to clipboard'")
                    end },
                    { "Delete", function()
                        get_history().delete(n.id)
                        widget.refresh()
                    end },
                }
            })
            menu:show()
        end)
    ))
    
    return item
end

-- Refresh the notifications list
function widget.refresh()
    if not notifications_list then return end
    
    notifications_list:reset()
    
    local h = get_history()
    local notifications
    
    if current_filter == "today" then
        notifications = h.filter_by_days(1)
    elseif current_filter == "week" then
        notifications = h.filter_by_days(7)
    else
        notifications = h.get_recent(MAX_VISIBLE_ITEMS)
    end
    
    local count = 0
    for _, n in ipairs(notifications) do
        if count >= MAX_VISIBLE_ITEMS then break end
        notifications_list:add(create_notification_item(n))
        count = count + 1
    end
    
    if count == 0 then
        notifications_list:add(wibox.widget {
            {
                text = "No notifications",
                font = "Sans 11",
                align = "center",
                widget = wibox.widget.textbox,
            },
            forced_height = dpi(80),
            valign = "center",
            widget = wibox.container.place,
        })
    end
end

-- Create filter button
local function create_filter_button(text, filter_name)
    local btn = wibox.widget {
        {
            {
                text = text,
                font = "Sans 10",
                align = "center",
                widget = wibox.widget.textbox,
            },
            left = dpi(12),
            right = dpi(12),
            top = dpi(4),
            bottom = dpi(4),
            widget = wibox.container.margin,
        },
        bg = current_filter == filter_name and accent_color or bg_color,
        fg = current_filter == filter_name and "#ffffff" or fg_color,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(12))
        end,
        widget = wibox.container.background,
    }
    
    btn:buttons(gears.table.join(
        awful.button({}, 1, function()
            current_filter = filter_name
            widget.refresh()
            widget.update_filters()
        end)
    ))
    
    btn:connect_signal("mouse::enter", function(self)
        if current_filter ~= filter_name then
            self.bg = bg_focus
        end
    end)
    
    btn:connect_signal("mouse::leave", function(self)
        if current_filter ~= filter_name then
            self.bg = bg_color
        end
    end)
    
    return btn
end

local filter_buttons = {}

function widget.update_filters()
    for name, btn in pairs(filter_buttons) do
        if name == current_filter then
            btn.bg = accent_color
            btn.fg = "#ffffff"
        else
            btn.bg = bg_color
            btn.fg = fg_color
        end
    end
end

-- Create the popup widget
local function create_popup()
    notifications_list = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = dpi(6),
    }
    
    filter_buttons.all = create_filter_button("All", "all")
    filter_buttons.today = create_filter_button("Today", "today")
    filter_buttons.week = create_filter_button("Week", "week")
    
    -- Header (simple, no Clear All button)
    local header = wibox.widget {
        {
            {
                text = "Notifications",
                font = "Sans Bold 13",
                widget = wibox.widget.textbox,
            },
            nil,
            {
                text = "Click to copy, Right-click for options",
                font = "Sans 8",
                widget = wibox.widget.textbox,
            },
            layout = wibox.layout.align.horizontal,
        },
        margins = dpi(12),
        widget = wibox.container.margin,
    }
    
    -- Filter bar
    local filter_bar = wibox.widget {
        {
            filter_buttons.all,
            filter_buttons.today,
            filter_buttons.week,
            spacing = dpi(8),
            layout = wibox.layout.fixed.horizontal,
        },
        left = dpi(12),
        right = dpi(12),
        bottom = dpi(8),
        widget = wibox.container.margin,
    }
    
    -- Main layout
    local main_widget = wibox.widget {
        {
            header,
            {
                bg = border_color,
                forced_height = dpi(1),
                widget = wibox.container.background,
            },
            filter_bar,
            {
                notifications_list,
                margins = dpi(8),
                widget = wibox.container.margin,
            },
            layout = wibox.layout.fixed.vertical,
        },
        bg = bg_color,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(12))
        end,
        border_width = dpi(1),
        border_color = border_color,
        widget = wibox.container.background,
    }
    
    popup = awful.popup {
        widget = main_widget,
        placement = function(d)
            awful.placement.top_right(d, {
                margins = { top = dpi(35), right = dpi(10) },
            })
        end,
        ontop = true,
        visible = false,
        bg = "#00000000",
        minimum_width = WIDGET_WIDTH,
        maximum_width = WIDGET_WIDTH,
    }
    
    popup:connect_signal("button::press", function(_, _, _, button)
        if button == 3 then widget.hide() end
    end)
    
    return popup
end

function widget.show()
    if not popup then popup = create_popup() end
    widget.refresh()
    popup.visible = true
end

function widget.hide()
    if popup then popup.visible = false end
end

function widget.toggle()
    if not popup then popup = create_popup() end
    if popup.visible then widget.hide() else widget.show() end
end

return widget
