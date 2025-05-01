--[[

     Powerarrow Dark Awesome WM theme
     github.com/lcpz

--]]

local gears = require("gears")
local lain  = require("lain")
local awful = require("awful")
local wibox = require("wibox")
local dpi   = require("beautiful.xresources").apply_dpi

local os = os
local my_table = awful.util.table or gears.table -- 4.{0,1} compatibility

local theme                                     = {}
theme.dir                                       = os.getenv("HOME") .. "/.config/awesome/themes/powerarrow-dark"
theme.wallpaper                                 = theme.dir .. "/microcircuit_circuit_bw_126894_1920x1080.jpg"
theme.font                                      = "Terminus 9"
theme.fg_normal                                 = "#DDDDFF"
theme.fg_focus                                  = "#EA6F81"
theme.fg_urgent                                 = "#CC9393"
theme.bg_normal                                 = "#1A1A1A"
theme.bg_focus                                  = "#313131"
theme.bg_urgent                                 = "#1A1A1A"
theme.border_width                              = dpi(1)
theme.border_normal                             = "#3F3F3F"
theme.border_focus                              = "#7F7F7F"
theme.border_marked                             = "#CC9393"
theme.tasklist_bg_focus                         = "#1A1A1A"
theme.titlebar_bg_focus                         = theme.bg_focus
theme.titlebar_bg_normal                        = theme.bg_normal
theme.titlebar_fg_focus                         = theme.fg_focus
theme.menu_height                               = dpi(16)
theme.menu_width                                = dpi(140)
theme.menu_submenu_icon                         = theme.dir .. "/icons/submenu.png"
theme.taglist_squares_sel                       = theme.dir .. "/icons/square_sel.png"
theme.taglist_squares_unsel                     = theme.dir .. "/icons/square_unsel.png"
theme.layout_tile                               = theme.dir .. "/icons/tile.png"
theme.layout_tileleft                           = theme.dir .. "/icons/tileleft.png"
theme.layout_tilebottom                         = theme.dir .. "/icons/tilebottom.png"
theme.layout_tiletop                            = theme.dir .. "/icons/tiletop.png"
theme.layout_fairv                              = theme.dir .. "/icons/fairv.png"
theme.layout_fairh                              = theme.dir .. "/icons/fairh.png"
theme.layout_spiral                             = theme.dir .. "/icons/spiral.png"
theme.layout_dwindle                            = theme.dir .. "/icons/dwindle.png"
theme.layout_max                                = theme.dir .. "/icons/max.png"
theme.layout_fullscreen                         = theme.dir .. "/icons/fullscreen.png"
theme.layout_magnifier                          = theme.dir .. "/icons/magnifier.png"
theme.layout_floating                           = theme.dir .. "/icons/floating.png"
theme.widget_ac                                 = theme.dir .. "/icons/ac.png"
theme.widget_battery                            = theme.dir .. "/icons/battery.png"
theme.widget_battery_low                        = theme.dir .. "/icons/battery_low.png"
theme.widget_battery_empty                      = theme.dir .. "/icons/battery_empty.png"
theme.widget_mem                                = theme.dir .. "/icons/mem.png"
theme.widget_cpu                                = theme.dir .. "/icons/cpu.png"
theme.widget_temp                               = theme.dir .. "/icons/temp.png"
theme.widget_net                                = theme.dir .. "/icons/net.png"
theme.widget_hdd                                = theme.dir .. "/icons/hdd.png"
theme.widget_music                              = theme.dir .. "/icons/note.png"
theme.widget_music_on                           = theme.dir .. "/icons/note_on.png"
theme.widget_vol                                = theme.dir .. "/icons/vol.png"
theme.widget_vol_low                            = theme.dir .. "/icons/vol_low.png"
theme.widget_vol_no                             = theme.dir .. "/icons/vol_no.png"
theme.widget_vol_mute                           = theme.dir .. "/icons/vol_mute.png"
theme.widget_mail                               = theme.dir .. "/icons/mail.png"
theme.widget_mail_on                            = theme.dir .. "/icons/mail_on.png"
theme.tasklist_plain_task_name                  = true
theme.tasklist_disable_icon                     = true
theme.useless_gap                               = dpi(0)
theme.titlebar_close_button_focus               = theme.dir .. "/icons/titlebar/close_focus.png"
theme.titlebar_close_button_normal              = theme.dir .. "/icons/titlebar/close_normal.png"
theme.titlebar_ontop_button_focus_active        = theme.dir .. "/icons/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active       = theme.dir .. "/icons/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive      = theme.dir .. "/icons/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive     = theme.dir .. "/icons/titlebar/ontop_normal_inactive.png"
theme.titlebar_sticky_button_focus_active       = theme.dir .. "/icons/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active      = theme.dir .. "/icons/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive     = theme.dir .. "/icons/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive    = theme.dir .. "/icons/titlebar/sticky_normal_inactive.png"
theme.titlebar_floating_button_focus_active     = theme.dir .. "/icons/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active    = theme.dir .. "/icons/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive   = theme.dir .. "/icons/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive  = theme.dir .. "/icons/titlebar/floating_normal_inactive.png"
theme.titlebar_maximized_button_focus_active    = theme.dir .. "/icons/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active   = theme.dir .. "/icons/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive  = theme.dir .. "/icons/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = theme.dir .. "/icons/titlebar/maximized_normal_inactive.png"

local markup = lain.util.markup
local separators = lain.util.separators

local keyboardlayout = awful.widget.keyboardlayout:new()

-- Textclock
local clockicon = wibox.widget.imagebox(theme.widget_clock)
local textclock = wibox.widget.textclock(" %a %d %b %R ")

-- Calendar
theme.cal = lain.widget.cal({
    attach_to = { textclock },
    notification_preset = {
        font = "Terminus 10",
        fg   = theme.fg_normal,
        bg   = theme.bg_normal
    }
})

-- Mail IMAP check
local mailicon = wibox.widget.imagebox(theme.widget_mail)
--[[ commented because it needs to be set before use
mailicon:buttons(my_table.join(awful.button({ }, 1, function () awful.spawn(mail) end)))
theme.mail = lain.widget.imap({
    timeout  = 180,
    server   = "server",
    mail     = "mail",
    password = "keyring get mail",
    settings = function()
        if mailcount > 0 then
            widget:set_markup(markup.font(theme.font, " " .. mailcount .. " "))
            mailicon:set_image(theme.widget_mail_on)
        else
            widget:set_text("")
            mailicon:set_image(theme.widget_mail)
        end
    end
})
--]]

-- MPD
local musicplr = awful.util.terminal .. " -title Music -e ncmpcpp"
local mpdicon = wibox.widget.imagebox(theme.widget_music)
mpdicon:buttons(my_table.join(
    awful.button({ "Mod4" }, 1, function () awful.spawn(musicplr) end),
    awful.button({ }, 1, function ()
        os.execute("mpc prev")
        theme.mpd.update()
    end),
    awful.button({ }, 2, function ()
        os.execute("mpc toggle")
        theme.mpd.update()
    end),
    awful.button({ }, 3, function ()
        os.execute("mpc next")
        theme.mpd.update()
    end)))
theme.mpd = lain.widget.mpd({
    settings = function()
        if mpd_now.state == "play" then
            artist = " " .. mpd_now.artist .. " "
            title  = mpd_now.title  .. " "
            mpdicon:set_image(theme.widget_music_on)
        elseif mpd_now.state == "pause" then
            artist = " mpd "
            title  = "paused "
        else
            artist = ""
            title  = ""
            mpdicon:set_image(theme.widget_music)
        end

        widget:set_markup(markup.font(theme.font, markup("#EA6F81", artist) .. title))
    end
})

-- MEM
local memicon = wibox.widget.imagebox(theme.widget_mem)
local mem = lain.widget.mem({
    settings = function()
        widget:set_markup(markup.font(theme.font, " " .. mem_now.used .. "MB "))
    end
})

-- CPU
local cpuicon = wibox.widget.imagebox(theme.widget_cpu)
local cpu = lain.widget.cpu({
    settings = function()
        widget:set_markup(markup.font(theme.font, " " .. cpu_now.usage .. "% "))
    end
})

-- Coretemp
local tempicon = wibox.widget.imagebox(theme.widget_temp)
local temp = lain.widget.temp({
    settings = function()
        widget:set_markup(markup.font(theme.font, " " .. coretemp_now .. "°C "))
    end
})

-- / fs
local fsicon = wibox.widget.imagebox(theme.widget_hdd)
--[[ commented because it needs Gio/Glib >= 2.54
theme.fs = lain.widget.fs({
    notification_preset = { fg = theme.fg_normal, bg = theme.bg_normal, font = "Terminus 10" },
    settings = function()
        widget:set_markup(markup.font(theme.font, " " .. fs_now["/"].percentage .. "% "))
    end
})
--]]

-- Battery
local baticon = wibox.widget.imagebox(theme.widget_battery)
local bat = lain.widget.bat({
    settings = function()
        if bat_now.status and bat_now.status ~= "N/A" then
            if bat_now.ac_status == 1 then
                baticon:set_image(theme.widget_ac)
            elseif not bat_now.perc and tonumber(bat_now.perc) <= 5 then
                baticon:set_image(theme.widget_battery_empty)
            elseif not bat_now.perc and tonumber(bat_now.perc) <= 15 then
                baticon:set_image(theme.widget_battery_low)
            else
                baticon:set_image(theme.widget_battery)
            end
            widget:set_markup(markup.font(theme.font, " " .. bat_now.perc .. "% "))
        else
            widget:set_markup(markup.font(theme.font, " AC "))
            baticon:set_image(theme.widget_ac)
        end
    end
})
-- ALSA volume
local volicon = wibox.widget.imagebox(theme.widget_vol)
local volume_widget = wibox.widget.textbox() -- Create a new widget for volume
theme.volume = lain.widget.alsa({
    settings = function()
        if volume_now.status == "off" then
            volicon:set_image(theme.widget_vol_mute)
        elseif tonumber(volume_now.level) == 0 then
            volicon:set_image(theme.widget_vol_no)
        elseif tonumber(volume_now.level) <= 50 then
            volicon:set_image(theme.widget_vol_low)
        else
            volicon:set_image(theme.widget_vol)
        end

        volume_widget:set_markup(markup.font(theme.font, " " .. volume_now.level .. "% "))
    end
})
theme.volume.widget = volume_widget
theme.volume.widget:buttons(awful.util.table.join(
                               awful.button({}, 4, function ()
                                     awful.util.spawn("amixer set Master 1%+")
                                     theme.volume.update()
                                     show_volume_popup()
                               end),
                               awful.button({}, 5, function ()
                                     awful.util.spawn("amixer set Master 1%-")
                                     theme.volume.update()
                                     show_volume_popup()
                               end),
                               awful.button({}, 1, function ()
                                     awful.util.spawn("amixer set Master toggle")
                                     theme.volume.update()
                                     show_volume_popup()
                               end)
))

-- Net
local neticon = wibox.widget.imagebox(theme.widget_net)
local net_widget = wibox.widget.textbox() -- Create a new widget for network
local net = lain.widget.net({
    settings = function()
        -- Fetch network name (SSID)
        awful.spawn.easy_async("iwgetid --raw", function(ssid)
            -- Fetch signal power
            awful.spawn.easy_async("iwconfig 2>/dev/null | grep 'Link Quality' | awk '{print $2}' | tr -d '='", function(signal)
                net_widget:set_markup(markup.font(theme.font,
                                  markup("#7AC82E", " " .. ssid)
                                  .. " " ..
                                  markup("#46A8C3", " " .. signal .. " ")))
            end)
        end)
    end
})
net.widget = net_widget
 
-- Initialize systray animation variables
local systray_original_width = dpi(200) -- Approximate default width
local systray_anim_duration = 0.3 -- Animation duration in seconds
local systray_anim_steps = 20
local systray_anim_step_time = systray_anim_duration / systray_anim_steps
local systray_slide_timer = nil
local bounce_timer = nil

-- Create the system tray widget
local systray = wibox.widget.systray()
systray.visible = true -- Make the system tray visible by default

-- Improve systray spacing and appearance
systray.base_size = dpi(20) -- Make icons slightly larger
systray.opacity = 0.9 -- Slightly transparent icons

-- Create a styled container for the system tray
local systray_container = wibox.container.margin(
    wibox.container.background(
        systray,
        (theme.bg_focus or "#535d6c") .. "70" -- More transparent background
    ),
    6, 6, 3, 3 -- Margins: left, right, top, bottom - increased for better visibility
)
systray_container.shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, 6) end -- More rounded corners

-- Create styled system tray with toggle button
local systray_toggle = wibox.widget {
    {
    {
        {
            id = "icon",
                -- Use a nicer-looking icon 
                text = "󰀻", -- Using a Nerd Font app tray icon (fallback to alternative if not available)
                font = "Symbols Nerd Font 18",
                align = "center",
                valign = "center",
            widget = wibox.widget.textbox,
        },
            id = "icon_margin",
            left = dpi(8),
            right = dpi(8),
            top = dpi(6),
            bottom = dpi(6),
        widget = wibox.container.margin
    },
        id = "icon_container",
        shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dpi(6)) end,
        bg = {
            type = "linear",
            from = { 0, 0 },
            to = { 0, dpi(40) },
            stops = { 
                { 0, theme.bg_focus .. "90" },
                { 1, theme.bg_focus .. "60" } 
            }
        },
        widget = wibox.container.background
    },
    -- Add a subtle border glow
    shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dpi(6)) end,
    border_width = dpi(1),
    border_color = theme.fg_focus .. "30",
    widget = wibox.container.background
}

-- Add a subtle border glow
local systray_toggle_with_border = wibox.widget {
    systray_toggle,
    shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dpi(6)) end,
    border_width = dpi(1),
    border_color = theme.fg_focus .. "30",
    widget = wibox.container.background
}

-- Add tooltip to explain functionality
local systray_tooltip = awful.tooltip({
    objects = {systray_toggle_with_border},
    text = "Toggle system tray visibility",
    delay_show = 0.5,
    margin_leftright = dpi(8),
    margin_topbottom = dpi(6),
    mode = "outside",
    preferred_positions = {"bottom", "top", "right", "left"},
    font = theme.font,
    bg = theme.bg_focus .. "90",
    border_width = dpi(1),
    border_color = theme.fg_focus .. "40",
})

-- Make sure we have a fallback for the icon if Nerd Fonts aren't available
awful.spawn.easy_async_with_shell("fc-list | grep -i 'nerd\\|awesome'", function(stdout)
    local has_special_fonts = stdout ~= ""
    local icon_widget = systray_toggle:get_children_by_id("icon")[1]
    
    if not has_special_fonts then
        -- Fallback to a standard icon if Nerd Fonts aren't available
        icon_widget.text = "☰" -- A nice fallback icon that should work in most fonts
        icon_widget.font = "sans 16"
    end
end)

-- Enhance the hover effect with animation
local icon_opacity = 0.9
local hover_timer = nil

systray_toggle:connect_signal("mouse::enter", function(w)
    -- Stop any existing animation
    if hover_timer then
        hover_timer:stop()
    end
    
    -- Create smooth glow animation
    icon_opacity = 0.9
    hover_timer = gears.timer {
        timeout = 0.05,
        call_now = true,
        autostart = true,
        callback = function(t)
            icon_opacity = icon_opacity + 0.05
            if icon_opacity >= 1.0 then
                t:stop()
                icon_opacity = 1.0
            end
            
            -- Update the widget appearance with glow effect
            local icon_container = systray_toggle:get_children_by_id("icon_container")[1]
            icon_container.bg = {
                type = "linear",
                from = { 0, 0 },
                to = { 0, dpi(40) },
                stops = { 
                    { 0, theme.fg_focus .. "40" },
                    { 1, theme.bg_focus .. "90" } 
                }
            }
            
            -- Add glow to text
            local icon = systray_toggle:get_children_by_id("icon")[1]
            icon.markup = "<span foreground='" .. theme.fg_focus .. "'>" .. 
                          (icon.text and icon.text or "☰") .. "</span>"
            
            -- Update border glow
            w.border_color = theme.fg_focus .. "60"
        end
    }
end)

systray_toggle:connect_signal("mouse::leave", function(w)
    -- Stop any existing animation
    if hover_timer then
        hover_timer:stop()
    end
    
    -- Create smooth fade-out animation
    icon_opacity = 1.0
    hover_timer = gears.timer {
        timeout = 0.05,
        call_now = true,
        autostart = true,
        callback = function(t)
            icon_opacity = icon_opacity - 0.05
            if icon_opacity <= 0.9 then
                t:stop()
                icon_opacity = 0.9
            end
            
            -- Restore original appearance
            local icon_container = systray_toggle:get_children_by_id("icon_container")[1]
            icon_container.bg = {
                type = "linear",
                from = { 0, 0 },
                to = { 0, dpi(40) },
                stops = { 
                    { 0, theme.bg_focus .. "90" },
                    { 1, theme.bg_focus .. "60" } 
                }
            }
            
            -- Restore original text
            local icon = systray_toggle:get_children_by_id("icon")[1]
            icon.markup = "<span foreground='" .. theme.fg_normal .. "'>" ..
                          (icon.text and icon.text or "☰") .. "</span>"
            
            -- Restore border
            w.border_color = theme.fg_focus .. "30"
        end
    }
end)

-- Toggle functionality
local is_open = true
systray_toggle_with_border:buttons(my_table.join(
    awful.button({}, 1, function()
        -- Stop any existing animation
        if systray_slide_timer then
            systray_slide_timer:stop()
        end
        
        is_open = not is_open
        local icon = systray_toggle:get_children_by_id("icon")[1]
        
        -- Get the current width of the systray container
        local current_width = systray_container.forced_width or systray_original_width
        
        if is_open then
            -- Show open icon
            if icon.text == "󰀻" then
                icon.text = "󰀻" -- Keep Nerd Font icon if available
            else
                icon.text = "☰" -- Fallback
            end
            
            -- Show and animate systray expanding
            systray.visible = true
            systray_container.forced_width = 0
            
            local step = 0
            systray_slide_timer = gears.timer {
                timeout = systray_anim_step_time,
                call_now = true,
                autostart = true,
                callback = function(t)
                    step = step + 1
                    -- Use easing function for smoother animation
                    local progress = step / systray_anim_steps
                    local eased_progress = progress * (2 - progress) -- Ease out quad
                    
                    systray_container.forced_width = math.floor(systray_original_width * eased_progress)
                    
                    if step >= systray_anim_steps then
                        -- Add a small bounce effect at the end
                        if not bounce_timer then
                            local bounce_step = 0
                            local bounce_steps = 5
                            local bounce_amount = systray_original_width * 0.02 -- 2% bounce
                            
                            bounce_timer = gears.timer {
                                timeout = 0.02,
                                call_now = true,
                                autostart = true,
                                callback = function(bt)
                                    bounce_step = bounce_step + 1
                                    local bounce_progress = bounce_step / bounce_steps
                                    
                                    -- Sine wave for bounce: starts at 0, peaks at PI/2, returns to 0 at PI
                                    local bounce_factor = math.sin(bounce_progress * math.pi)
                                    local width_adjust = bounce_amount * bounce_factor
                                    
                                    systray_container.forced_width = systray_original_width + width_adjust
                                    
                                    if bounce_step >= bounce_steps then
                                        systray_container.forced_width = systray_original_width
                                        bt:stop()
                                        bounce_timer = nil
                                    end
                                end
                            }
                        end
                        t:stop()
                    end
                end
            }
        else
            -- Show closed icon
            if icon.text == "󰀻" then
                icon.text = "󰅁" -- Use Nerd Font alternative icon
            else
                icon.text = "✕" -- Fallback
            end
            
            -- Animate systray collapsing
            local step = 0
            local start_width = systray_container.forced_width or systray_original_width
            
            systray_slide_timer = gears.timer {
                timeout = systray_anim_step_time,
                call_now = true,
                autostart = true,
                callback = function(t)
                    step = step + 1
                    -- Use easing function for smoother animation
                    local progress = step / systray_anim_steps
                    local eased_progress = progress * (2 - progress) -- Ease out quad
                    
                    systray_container.forced_width = math.floor(start_width * (1 - eased_progress))
                    
                    if step >= systray_anim_steps then
                        -- Add a small bounce effect at the end for the toggle button
                        if not bounce_timer then
                            local bounce_step = 0
                            local bounce_steps = 5
                            
                            bounce_timer = gears.timer {
                                timeout = 0.02,
                                call_now = true,
                                autostart = true,
                                callback = function(bt)
                                    bounce_step = bounce_step + 1
                                    local bounce_progress = bounce_step / bounce_steps
                                    
                                    -- Small scale animation for the icon
                                    local icon_margin = systray_toggle:get_children_by_id("icon_margin")[1]
                                    local bounce_factor = math.sin(bounce_progress * math.pi)
                                    local scale = 1 - (bounce_factor * 0.1) -- Small 10% scale down and up
                                    
                                    icon_margin.left = dpi(8 * scale)
                                    icon_margin.right = dpi(8 * scale)
                                    icon_margin.top = dpi(6 * scale)
                                    icon_margin.bottom = dpi(6 * scale)
                                    
                                    if bounce_step >= bounce_steps then
                                        icon_margin.left = dpi(8)
                                        icon_margin.right = dpi(8)
                                        icon_margin.top = dpi(6)
                                        icon_margin.bottom = dpi(6)
                                        bt:stop()
                                        bounce_timer = nil
                                    end
                                end
                            }
                        end
                        
                        systray_container.forced_width = 0
                        systray.visible = false -- Hide after animation completes
                        t:stop()
                    end
                end
            }
        end
    end)
))

-- Separators
local spr     = wibox.widget.textbox(' ')
local arrl_dl = separators.arrow_left(theme.bg_focus, "alpha")
local arrl_ld = separators.arrow_left("alpha", theme.bg_focus)

-- Helper function for creating consistent rounded containers with glass effect
function theme.create_widget_container(widget, args)
    args = args or {}
    local bg_color = args.bg_color or (theme.bg_focus .. "80")  -- 50% transparency
    local fg_color = args.fg_color or theme.fg_normal
    local radius = args.radius or dpi(8)
    local padding = args.padding or {
        left = dpi(8), 
        right = dpi(8), 
        top = dpi(5), 
        bottom = dpi(5)
    }
    
    -- Create padded widget
    local padded_widget = wibox.container.margin(
        widget,
        padding.left, padding.right, padding.top, padding.bottom
    )
    
    -- Create background container
    local container = wibox.container.background(padded_widget)
    container.bg = bg_color
    container.fg = fg_color
    container.shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, radius)
    end
    
    -- Add a subtle border if specified
    if args.border_width then
        container.border_width = args.border_width
        container.border_color = args.border_color or (theme.bg_focus .. "60")
    end
    
    return container
end

-- Helper function to create widget groups with proper spacing
function theme.create_widget_group(widgets, args)
    args = args or {}
    local spacing = args.spacing or dpi(6)
    local group_bg = args.bg_color or "transparent"
    local group_radius = args.radius or dpi(10)
    
    local widget_group = wibox.layout.fixed.horizontal()
    widget_group.spacing = spacing
    
    for _, w in ipairs(widgets) do
        widget_group:add(w)
    end
    
    if group_bg ~= "transparent" then
        local container = wibox.container.background(
            wibox.container.margin(widget_group, dpi(6), dpi(6), dpi(3), dpi(3)),
            group_bg
        )
        container.shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, group_radius)
        end
        return container
    else
        return widget_group
    end
end

function theme.at_screen_connect(s)
    -- Quake application
    s.quake = lain.util.quake({ app = awful.util.terminal })

    -- If wallpaper is a function, call it with the screen
    local wallpaper = theme.wallpaper
    if type(wallpaper) == "function" then
        wallpaper = wallpaper(s)
    end
    gears.wallpaper.maximized(wallpaper, s, true)

    -- Tags
    awful.tag(awful.util.tagnames, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(my_table.join(
                           awful.button({}, 1, function () awful.layout.inc( 1) end),
                           awful.button({}, 2, function () awful.layout.set( awful.layout.layouts[1] ) end),
                           awful.button({}, 3, function () awful.layout.inc(-1) end),
                           awful.button({}, 4, function () awful.layout.inc( 1) end),
                           awful.button({}, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, awful.util.taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, awful.util.tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ 
        position = "top", 
        screen = s, 
        height = dpi(32), -- Slightly taller for better visibility
        bg = theme.bg_normal .. "90",  -- More transparency for glass effect
        fg = theme.fg_normal 
    })
    
    -- Add a better shadow and rounded corners to the wibox
    s.mywibox.shape = function(cr, w, h)
        gears.shape.partially_rounded_rect(cr, w, h, false, false, true, true, dpi(12))
    end

    -- Create styled system tray with toggle button
    local systray = wibox.widget.systray()
    systray.base_size = dpi(22)
    
    local systray_container = theme.create_widget_container(systray, {
        bg_color = theme.bg_normal .. "90",
        radius = dpi(8),
        padding = {left = dpi(10), right = dpi(10), top = dpi(3), bottom = dpi(3)}
    })
    
    -- Create a beautiful toggle button with gradient and icon
    local systray_toggle = wibox.widget {
        {
            {
                id = "icon",
                -- Use a nicer-looking icon 
                text = "󰀻", -- Using a Nerd Font app tray icon (fallback to alternative if not available)
                font = "Symbols Nerd Font 18",
                align = "center",
                valign = "center",
                widget = wibox.widget.textbox,
            },
            id = "icon_margin",
            left = dpi(8),
            right = dpi(8),
            top = dpi(6),
            bottom = dpi(6),
            widget = wibox.container.margin
        },
        id = "icon_container",
        shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dpi(6)) end,
        bg = {
            type = "linear",
            from = { 0, 0 },
            to = { 0, dpi(40) },
            stops = { 
                { 0, theme.bg_focus .. "90" },
                { 1, theme.bg_focus .. "60" } 
            }
        },
        widget = wibox.container.background
    }
    
    -- Add a subtle border glow
    local systray_toggle_with_border = wibox.widget {
        systray_toggle,
        shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, dpi(6)) end,
        border_width = dpi(1),
        border_color = theme.fg_focus .. "30",
        widget = wibox.container.background
    }
    
    -- Add tooltip to explain functionality
    local systray_tooltip = awful.tooltip({
        objects = {systray_toggle_with_border},
        text = "Toggle system tray visibility",
        delay_show = 0.5,
        margin_leftright = dpi(8),
        margin_topbottom = dpi(6),
        mode = "outside",
        preferred_positions = {"bottom", "top", "right", "left"},
        font = theme.font,
        bg = theme.bg_focus .. "90",
        border_width = dpi(1),
        border_color = theme.fg_focus .. "40",
    })
    
    -- Make sure we have a fallback for the icon if Nerd Fonts aren't available
    awful.spawn.easy_async_with_shell("fc-list | grep -i 'nerd\\|awesome'", function(stdout)
        local has_special_fonts = stdout ~= ""
        local icon_widget = systray_toggle:get_children_by_id("icon")[1]
        
        if not has_special_fonts then
            -- Fallback to a standard icon if Nerd Fonts aren't available
            icon_widget.text = "☰" -- A nice fallback icon that should work in most fonts
            icon_widget.font = "sans 16"
        end
    end)
    
    -- Enhance the hover effect with animation
    local icon_opacity = 0.9
    local hover_timer = nil
    
    systray_toggle_with_border:connect_signal("mouse::enter", function(w)
        -- Stop any existing animation
        if hover_timer then
            hover_timer:stop()
        end
        
        -- Create smooth glow animation
        icon_opacity = 0.9
        hover_timer = gears.timer {
            timeout = 0.05,
            call_now = true,
            autostart = true,
            callback = function(t)
                icon_opacity = icon_opacity + 0.05
                if icon_opacity >= 1.0 then
                    t:stop()
                    icon_opacity = 1.0
                end
                
                -- Update the widget appearance with glow effect
                local icon_container = systray_toggle:get_children_by_id("icon_container")[1]
                icon_container.bg = {
                    type = "linear",
                    from = { 0, 0 },
                    to = { 0, dpi(40) },
                    stops = { 
                        { 0, theme.fg_focus .. "40" },
                        { 1, theme.bg_focus .. "90" } 
                    }
                }
                
                -- Add glow to text
                local icon = systray_toggle:get_children_by_id("icon")[1]
                icon.markup = "<span foreground='" .. theme.fg_focus .. "'>" .. 
                              (icon.text and icon.text or "☰") .. "</span>"
                
                -- Update border glow
                w.border_color = theme.fg_focus .. "60"
            end
        }
    end)
    
    systray_toggle_with_border:connect_signal("mouse::leave", function(w)
        -- Stop any existing animation
        if hover_timer then
            hover_timer:stop()
        end
        
        -- Create smooth fade-out animation
        icon_opacity = 1.0
        hover_timer = gears.timer {
            timeout = 0.05,
            call_now = true,
            autostart = true,
            callback = function(t)
                icon_opacity = icon_opacity - 0.05
                if icon_opacity <= 0.9 then
                    t:stop()
                    icon_opacity = 0.9
                end
                
                -- Restore original appearance
                local icon_container = systray_toggle:get_children_by_id("icon_container")[1]
                icon_container.bg = {
                    type = "linear",
                    from = { 0, 0 },
                    to = { 0, dpi(40) },
                    stops = { 
                        { 0, theme.bg_focus .. "90" },
                        { 1, theme.bg_focus .. "60" } 
                    }
                }
                
                -- Restore original text
                local icon = systray_toggle:get_children_by_id("icon")[1]
                icon.markup = "<span foreground='" .. theme.fg_normal .. "'>" ..
                              (icon.text and icon.text or "☰") .. "</span>"
                
                -- Restore border
                w.border_color = theme.fg_focus .. "30"
            end
        }
    end)
    
    -- Toggle functionality
    local is_open = true
    systray_toggle_with_border:buttons(my_table.join(
        awful.button({}, 1, function()
            -- Stop any existing animation
            if systray_slide_timer then
                systray_slide_timer:stop()
            end
            
            is_open = not is_open
            local icon = systray_toggle:get_children_by_id("icon")[1]
            
            -- Get the current width of the systray container
            local current_width = systray_container.forced_width or systray_original_width
            
            if is_open then
                -- Show open icon
                if icon.text == "󰀻" then
                    icon.text = "󰀻" -- Keep Nerd Font icon if available
                else
                    icon.text = "☰" -- Fallback
                end
                
                -- Show and animate systray expanding
                systray.visible = true
                systray_container.forced_width = 0
                
                local step = 0
                systray_slide_timer = gears.timer {
                    timeout = systray_anim_step_time,
                    call_now = true,
                    autostart = true,
                    callback = function(t)
                        step = step + 1
                        -- Use easing function for smoother animation
                        local progress = step / systray_anim_steps
                        local eased_progress = progress * (2 - progress) -- Ease out quad
                        
                        systray_container.forced_width = math.floor(systray_original_width * eased_progress)
                        
                        if step >= systray_anim_steps then
                            -- Add a small bounce effect at the end
                            if not bounce_timer then
                                local bounce_step = 0
                                local bounce_steps = 5
                                local bounce_amount = systray_original_width * 0.02 -- 2% bounce
                                
                                bounce_timer = gears.timer {
                                    timeout = 0.02,
                                    call_now = true,
                                    autostart = true,
                                    callback = function(bt)
                                        bounce_step = bounce_step + 1
                                        local bounce_progress = bounce_step / bounce_steps
                                        
                                        -- Sine wave for bounce: starts at 0, peaks at PI/2, returns to 0 at PI
                                        local bounce_factor = math.sin(bounce_progress * math.pi)
                                        local width_adjust = bounce_amount * bounce_factor
                                        
                                        systray_container.forced_width = systray_original_width + width_adjust
                                        
                                        if bounce_step >= bounce_steps then
                                            systray_container.forced_width = systray_original_width
                                            bt:stop()
                                            bounce_timer = nil
                                        end
                                    end
                                }
                            end
                            t:stop()
                        end
                    end
                }
            else
                -- Show closed icon
                if icon.text == "󰀻" then
                    icon.text = "󰅁" -- Use Nerd Font alternative icon
                else
                    icon.text = "✕" -- Fallback
                end
                
                -- Animate systray collapsing
                local step = 0
                local start_width = systray_container.forced_width or systray_original_width
                
                systray_slide_timer = gears.timer {
                    timeout = systray_anim_step_time,
                    call_now = true,
                    autostart = true,
                    callback = function(t)
                        step = step + 1
                        -- Use easing function for smoother animation
                        local progress = step / systray_anim_steps
                        local eased_progress = progress * (2 - progress) -- Ease out quad
                        
                        systray_container.forced_width = math.floor(start_width * (1 - eased_progress))
                        
                        if step >= systray_anim_steps then
                            -- Add a small bounce effect at the end for the toggle button
                            if not bounce_timer then
                                local bounce_step = 0
                                local bounce_steps = 5
                                
                                bounce_timer = gears.timer {
                                    timeout = 0.02,
                                    call_now = true,
                                    autostart = true,
                                    callback = function(bt)
                                        bounce_step = bounce_step + 1
                                        local bounce_progress = bounce_step / bounce_steps
                                        
                                        -- Small scale animation for the icon
                                        local icon_margin = systray_toggle:get_children_by_id("icon_margin")[1]
                                        local bounce_factor = math.sin(bounce_progress * math.pi)
                                        local scale = 1 - (bounce_factor * 0.1) -- Small 10% scale down and up
                                        
                                        icon_margin.left = dpi(8 * scale)
                                        icon_margin.right = dpi(8 * scale)
                                        icon_margin.top = dpi(6 * scale)
                                        icon_margin.bottom = dpi(6 * scale)
                                        
                                        if bounce_step >= bounce_steps then
                                            icon_margin.left = dpi(8)
                                            icon_margin.right = dpi(8)
                                            icon_margin.top = dpi(6)
                                            icon_margin.bottom = dpi(6)
                                            bt:stop()
                                            bounce_timer = nil
                                        end
                                    end
                                }
                            end
                            
                            systray_container.forced_width = 0
                            systray.visible = false -- Hide after animation completes
                            t:stop()
                        end
                    end
                }
            end
        end)
    ))
    
    -- Styled clock widget with icon
    local clock_widget = wibox.widget {
        {
            text = " ",  -- Icon: clock
            font = "FontAwesome 11",
            widget = wibox.widget.textbox,
        },
        textclock,  -- Use the textclock widget that the calendar is attached to
        spacing = dpi(4),
        layout = wibox.layout.fixed.horizontal
    }
    
    local styled_clock = theme.create_widget_container(clock_widget, {
        bg_color = theme.bg_focus .. "80",
        radius = dpi(8)
    })
    
    -- Styled volume widget
    local volume_widget = wibox.widget {
        {
            volicon,
            theme.volume.widget,
            spacing = dpi(4),
            layout = wibox.layout.fixed.horizontal
        },
        left = dpi(2),
        widget = wibox.container.margin
    }
    
    local styled_volume = theme.create_widget_container(volume_widget, {
        bg_color = theme.bg_focus .. "80",
        radius = dpi(8)
    })
    
    -- Style the CPU widget
    local cpu_widget = wibox.widget {
        {
                {
                text = " ",  -- Icon: microchip
                    font = "FontAwesome 11",
                    widget = wibox.widget.textbox,
                },
                cpu.widget,
            spacing = dpi(4),
            layout = wibox.layout.fixed.horizontal
        },
        left = dpi(2),
        widget = wibox.container.margin
    }
    
    local styled_cpu = theme.create_widget_container(cpu_widget, {
        bg_color = theme.bg_focus .. "80",
        radius = dpi(8)
    })
    
    -- Style the memory widget
    local mem_widget = wibox.widget {
        {
                {
                text = " ",  -- Icon: memory
                    font = "FontAwesome 11",
                    widget = wibox.widget.textbox,
                },
                mem.widget,
            spacing = dpi(4),
            layout = wibox.layout.fixed.horizontal
        },
        left = dpi(2),
        widget = wibox.container.margin
    }
    
    local styled_mem = theme.create_widget_container(mem_widget, {
        bg_color = theme.bg_focus .. "80",
        radius = dpi(8)
    })
    
    -- Style the battery widget
    local bat_widget = wibox.widget {
        {
                baticon,
                bat.widget,
            spacing = dpi(4),
            layout = wibox.layout.fixed.horizontal
        },
        left = dpi(2),
        widget = wibox.container.margin
    }
    
    local styled_bat = theme.create_widget_container(bat_widget, {
        bg_color = theme.bg_focus .. "80",
        radius = dpi(8)
    })
    
    -- Style the network widget
    local net_widget = wibox.widget {
        {
                neticon,
                net.widget,
            spacing = dpi(4),
            layout = wibox.layout.fixed.horizontal
        },
        left = dpi(2),
        widget = wibox.container.margin
    }
    
    local styled_net = theme.create_widget_container(net_widget, {
        bg_color = theme.bg_focus .. "80",
        radius = dpi(8)
    })
    
    -- Create styled keyboardlayout widget
    local kbd_widget = wibox.widget {
        {
                {
                text = " ",  -- Icon: keyboard
                    font = "FontAwesome 11",
                    widget = wibox.widget.textbox,
                },
                keyboardlayout,
            spacing = dpi(4),
            layout = wibox.layout.fixed.horizontal
        },
        left = dpi(2),
        widget = wibox.container.margin
    }
    
    local styled_keyboardlayout = theme.create_widget_container(kbd_widget, {
        bg_color = theme.bg_focus .. "80",
        radius = dpi(8)
    })
    
    -- Style the taglist
    local taglist_container = theme.create_widget_container(s.mytaglist, {
        bg_color = theme.bg_focus .. "70",
        radius = dpi(8),
        padding = {left = dpi(6), right = dpi(6), top = dpi(3), bottom = dpi(3)}
    })
    
    -- Style the layoutbox
    local layoutbox_container = theme.create_widget_container(s.mylayoutbox, {
        bg_color = theme.bg_focus .. "80",
        radius = dpi(8),
        padding = {left = dpi(8), right = dpi(8), top = dpi(6), bottom = dpi(6)}
    })
    
    -- Group similar widgets for better organization
    local system_info_group = theme.create_widget_group(
        {styled_cpu, styled_mem, styled_bat},
        {spacing = dpi(6)}
    )
    
    local network_group = theme.create_widget_group(
        {styled_net},
        {spacing = dpi(6)}
    )
    
    local controls_group = theme.create_widget_group(
        {styled_volume, styled_keyboardlayout},
        {spacing = dpi(6)}
    )
    
    local time_group = theme.create_widget_group(
        {styled_clock, layoutbox_container},
        {spacing = dpi(6)}
    )
    
    local systray_group = theme.create_widget_group(
        {systray_toggle_with_border, systray_container},
        {spacing = dpi(2)}
    )
    
    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(10),
            taglist_container,
            s.mypromptbox,
        },
        { -- Middle widget - empty
            layout = wibox.layout.flex.horizontal,
            nil,
        },
        { -- Right widgets
            id = "right_widgets",
            layout = wibox.layout.fixed.horizontal,
            spacing = dpi(10), -- Add spacing between groups
            systray_group,
            system_info_group,
            network_group,
            controls_group,
            time_group,
        },
    }
end

return theme
