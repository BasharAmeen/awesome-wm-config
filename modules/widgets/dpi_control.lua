local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local naughty = require("naughty")

-- Import our custom hidpi module
local hidpi = require("modules.hidpi")

-- Create the DPI control widget
local dpi_control = {}

-- Available DPI presets
local dpi_presets = {
    { name = "Standard (96)", value = 96 },
    { name = "Medium (144)", value = 144 },
    { name = "Large (192)", value = 192 },
    { name = "Extra Large (240)", value = 240 }
}

function dpi_control.create_popup()
    -- Create a popup for DPI settings
    local popup = awful.popup {
        ontop = true,
        visible = false,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(12))
        end,
        border_width = dpi(2),
        border_color = beautiful.border_focus,
        maximum_width = dpi(400),
        offset = { y = dpi(5) },
        widget = {}
    }

    -- Create the layout for the popup
    local layout = wibox.layout.fixed.vertical()
    layout.spacing = dpi(10)
    layout:add(wibox.widget {
        markup = "<b>DPI Scaling Control</b>",
        align = "center",
        widget = wibox.widget.textbox
    })

    -- Add a separator
    layout:add(wibox.widget {
        color = beautiful.border_focus,
        span_ratio = 0.9,
        widget = wibox.widget.separator
    })

    -- Add description
    layout:add(wibox.widget {
        markup = "Select a scaling preset for HiDPI displays:",
        align = "center",
        widget = wibox.widget.textbox
    })

    -- Add buttons for each DPI preset
    for _, preset in ipairs(dpi_presets) do
        local button = wibox.widget {
            {
                {
                    text = preset.name,
                    align = "center",
                    widget = wibox.widget.textbox
                },
                margins = dpi(12),
                widget = wibox.container.margin
            },
            bg = beautiful.bg_normal,
            shape = function(cr, w, h)
                gears.shape.rounded_rect(cr, w, h, dpi(8))
            end,
            widget = wibox.container.background
        }

        -- Hover effect
        button:connect_signal("mouse::enter", function()
            button.bg = beautiful.bg_focus
        end)
        button:connect_signal("mouse::leave", function()
            button.bg = beautiful.bg_normal
        end)

        -- Click action
        button:connect_signal("button::press", function()
            hidpi.set_dpi(preset.value)
            popup.visible = false
            awful.spawn.with_shell("echo 'Set DPI to " .. preset.value .. " via popup' >> $HOME/.config/awesome/hidpi_scaling.log")
        end)

        layout:add(button)
    end

    -- Add a button to apply immediately via script
    local apply_button = wibox.widget {
        {
            {
                text = "Apply and Restart AwesomeWM",
                align = "center",
                widget = wibox.widget.textbox
            },
            margins = dpi(12),
            widget = wibox.container.margin
        },
        bg = "#285577",
        fg = "#ffffff",
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(8))
        end,
        widget = wibox.container.background
    }

    -- Hover effect
    apply_button:connect_signal("mouse::enter", function()
        apply_button.bg = "#3465a4"
    end)
    apply_button:connect_signal("mouse::leave", function()
        apply_button.bg = "#285577"
    end)

    -- Click action to restart awesome
    apply_button:connect_signal("button::press", function()
        popup.visible = false
        awesome.restart()
    end)

    layout:add(apply_button)

    -- Add a text input field for custom DPI value
    local custom_dpi_textbox = wibox.widget {
        widget = wibox.widget.textbox,
        text = tostring(xresources.get_dpi() or 96),
        align = "center"
    }

    -- Create an editable text field with a frame
    local custom_dpi_input = wibox.widget {
        {
            {
                text = "Custom DPI: ",
                widget = wibox.widget.textbox
            },
            custom_dpi_textbox,
            layout = wibox.layout.align.horizontal
        },
        bg = beautiful.bg_normal,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(8))
        end,
        forced_height = dpi(36),
        widget = wibox.container.background
    }

    -- Allow custom input
    custom_dpi_input:connect_signal("button::press", function()
        awful.prompt.run {
            prompt = "Enter DPI value: ",
            textbox = custom_dpi_textbox,
            exe_callback = function(input)
                local dpi_value = tonumber(input)
                if dpi_value and dpi_value > 0 then
                    hidpi.set_dpi(dpi_value)
                    awful.spawn.with_shell("echo 'Set custom DPI to " .. dpi_value .. "' >> $HOME/.config/awesome/hidpi_scaling.log")
                else
                    naughty.notify({
                        title = "Invalid DPI",
                        text = "Please enter a valid number greater than 0",
                        timeout = 3
                    })
                end
            end
        }
    end)

    layout:add(custom_dpi_input)

    -- Add cancel button
    local cancel_button = wibox.widget {
        {
            {
                text = "Cancel",
                align = "center",
                widget = wibox.widget.textbox
            },
            margins = dpi(8),
            widget = wibox.container.margin
        },
        bg = beautiful.bg_normal,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(8))
        end,
        widget = wibox.container.background
    }

    -- Hover effect
    cancel_button:connect_signal("mouse::enter", function()
        cancel_button.bg = beautiful.bg_focus
    end)
    cancel_button:connect_signal("mouse::leave", function()
        cancel_button.bg = beautiful.bg_normal
    end)

    -- Click action
    cancel_button:connect_signal("button::press", function()
        popup.visible = false
    end)

    layout:add(cancel_button)

    -- Set the layout
    popup:setup {
        {
            layout,
            margins = dpi(20),
            widget = wibox.container.margin
        },
        bg = beautiful.bg_normal,
        widget = wibox.container.background
    }

    return popup
end

-- Create a button widget for the wibar
function dpi_control.create_button()
    local button = wibox.widget {
        {
            {
                text = "DPI",
                widget = wibox.widget.textbox
            },
            margins = dpi(4),
            widget = wibox.container.margin
        },
        bg = beautiful.bg_normal,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, dpi(4))
        end,
        widget = wibox.container.background
    }

    -- Create the popup
    local dpi_popup = dpi_control.create_popup()

    -- Hover effect
    button:connect_signal("mouse::enter", function()
        button.bg = beautiful.bg_focus
    end)
    button:connect_signal("mouse::leave", function()
        if not dpi_popup.visible then
            button.bg = beautiful.bg_normal
        end
    end)

    -- Click action
    button:connect_signal("button::press", function()
        if dpi_popup.visible then
            dpi_popup.visible = false
            button.bg = beautiful.bg_normal
        else
            dpi_popup:move_next_to(mouse.current_widget_geometry)
            button.bg = beautiful.bg_focus
        end
    end)

    -- Return the button widget
    return button
end

return dpi_control 