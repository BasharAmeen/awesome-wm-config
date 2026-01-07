# AwesomeWM Notification Center Module

A lightweight, persistent notification history module for Awesome Window Manager. It captures system notifications and lets you browse them later using **Rofi**.

## Features

- **Persistent History**: Saves notifications to `data/notifications/history.json`.
- **Rofi Interface**: Clean, searchable interface to view past notifications.
- **Copy to Clipboard**: Select a notification in Rofi to copy its content.
- **Icon Support**: Caches notification icons.

## Dependencies

Make sure you have these system packages installed:
- `awsome` (Window Manager)
- `rofi` (Application Launcher/Menu)
- `jq` (JSON processor)
- `xclip` or `xsel` (Clipboard utilities)

## Installation

1. Clone or copy this folder to your AwesomeWM config directory (usually `~/.config/awesome/modules/`).
   
   Structure should look like:
   ```
   ~/.config/awesome/modules/notification_center/
   ├── init.lua
   ├── history.lua
   ├── json.lua
   ├── rofi_viewer.sh
   └── README.md
   ```

2. Add the following to your `rc.lua`:

   ```lua
   -- Load the module
   local notification_center = require("modules.notification_center")
   ```

3. Bind a key to open the history:

   ```lua
   awful.key({ modkey }, "n", function()
       notification_center.show()
   end, {description = "show notification history", group = "launcher"}),
   ```

## Configuration

The history is saved in:
`~/.config/awesome/data/notifications/history.json`

Icons are cached in:
`~/.config/awesome/data/notifications/icons/`

## Troubleshooting

- **Script permission denied**: The module attempts to run `chmod +x` automatically, but you can manually run `chmod +x modules/notification_center/rofi_viewer.sh` if issues persist.
- **Empty list**: If Rofi opens but is empty, check if `jq` is installed correctly.

## How It Works

1. **Signal Interception**: Applications (like Discord, Firefox) send notifications over the **DBus** system bus. AwesomeWM's `naughty` library listens to these signals.
2. **Capture**: This module hooks into that process using `naughty.connect_signal("added", ...)` to grab the notification content immediately as it arrives.
3. **Store**: `history.lua` saves the notification data and icon to `history.json`.
4. **View**: When triggered, `rofi_viewer.sh` reads the JSON file and displays entries in Rofi.
5. **Interact**: Selecting an entry in Rofi copies its content to your clipboard.

## Developer Info

- **Developer**: Bashar Hlail
- **Website**: [https://basharhlail.com](https://basharhlail.com)
- **Tested On**: Arch Linux with AwesomeWM (git version)

> [!NOTE]
> This module was specifically designed for and tested on **Arch Linux**. Compatibility with other distributions is likely but not guaranteed.

