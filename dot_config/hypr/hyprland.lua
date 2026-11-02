-- ~/.config/hypr/hyprland.lua
--
-- Entry point only: each concern lives in its own module.
-- API reference: /usr/share/hypr/stubs/hl.meta.lua
-- Migration notes: ~/.config/docs/hyprland-lua.md

require("config.monitors")
require("config.env")
require("config.permissions")
require("config.look")
require("config.animations")
require("config.devices")
require("config.autostart")

require("binds.apps")
require("binds.windows")
require("binds.workspaces")
require("binds.media")

require("rules.windows")
require("rules.workspaces")
