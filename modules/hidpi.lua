local beautiful = require("beautiful")
local xresources = require("beautiful.xresources")
local naughty = require("naughty")
local awful = require("awful")
local gears = require("gears")

local hidpi = {}

-- Config values
hidpi.default_dpi = 96  -- Standard DPI
hidpi.hidpi_dpi = 192   -- Default HiDPI DPI (2x scaling)

-- Check if we're running on a HiDPI display
function hidpi.is_hidpi()
    -- Simple check: if any screen resolution is above 2560x1440
    local is_hidpi = false
    for s in screen do
        if s.geometry.width > 2560 or s.geometry.height > 1440 then
            is_hidpi = true
            break
        end
    end
    return is_hidpi
end

-- Apply HiDPI settings
function hidpi.setup(options)
    options = options or {}
    local dpi_value = options.dpi or (hidpi.is_hidpi() and hidpi.hidpi_dpi or hidpi.default_dpi)
    
    -- Log setup
    awful.spawn.with_shell("echo 'Setting up HiDPI with DPI: " .. dpi_value .. "' >> $HOME/.config/awesome/hidpi_scaling.log")
    
    -- Set the DPI value
    xresources.set_dpi(dpi_value)
    
    -- Scale UI elements according to DPI
    local scale_factor = dpi_value / 96
    
    -- If scale_factor > 1.3, we consider this a HiDPI display
    if scale_factor > 1.3 then
        -- Note: These environment variables will only affect applications started after this
        awful.spawn.with_shell("export GDK_SCALE=2")
        awful.spawn.with_shell("export GDK_DPI_SCALE=0.5")
        awful.spawn.with_shell("export QT_AUTO_SCREEN_SCALE_FACTOR=1")
        awful.spawn.with_shell("export QT_SCALE_FACTOR=2")
        
        -- Notify user that HiDPI mode is activated
        naughty.notify({
            title = "HiDPI Mode",
            text = "HiDPI scaling activated with DPI: " .. dpi_value,
            timeout = 5
        })
    end
    
    return scale_factor
end

-- Set DPI without restarting Awesome
function hidpi.set_dpi(dpi_value)
    xresources.set_dpi(dpi_value)
    
    -- Update the DPI value for X server
    awful.spawn.with_shell("echo 'Xft.dpi: " .. dpi_value .. "' | xrdb -merge")
    
    -- Notify user
    naughty.notify({
        title = "DPI Changed",
        text = "DPI set to " .. dpi_value .. ". Some applications may need to be restarted.",
        timeout = 5
    })
end

-- Apply a scaling factor to a number based on current DPI
function hidpi.scale(size)
    return xresources.apply_dpi(size)
end

-- Override beautiful.dpi function to ensure consistent scaling
beautiful.dpi = hidpi.scale

return hidpi 