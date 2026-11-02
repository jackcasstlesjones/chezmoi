local v = require("config.vars")
local mainMod, hyperKey = v.mainMod, v.hyperKey

-- Letter workspaces: hyperkey focuses, ALT+SHIFT moves the active window there.
local letterWorkspaces = { "C", "E", "D", "F", "V", "W", "X", "Z", "T", "M", "G", "4" }
for _, key in ipairs(letterWorkspaces) do
    hl.bind(hyperKey .. " + " .. key, hl.dsp.focus({ workspace = "name:" .. key }))
    hl.bind("ALT + SHIFT + " .. key,  hl.dsp.window.move({ workspace = "name:" .. key, follow = true }))
end

-- Workspace N is deliberately not in the loop: hyperkey+N is the scratchpad
-- above, and in hyprland.conf its `workspace name:N` bind was shadowed and never
-- fired. hyperkey+R is the working way to reach workspace N.
hl.bind("ALT + SHIFT + N", hl.dsp.window.move({ workspace = "name:N", follow = true }))
hl.bind(hyperKey .. " + R", hl.dsp.focus({ workspace = "name:N" }))

-- Alias: S -> M
hl.bind(hyperKey .. " + S", hl.dsp.focus({ workspace = "name:M" }))
hl.bind("ALT + SHIFT + S",  hl.dsp.window.move({ workspace = "name:M", follow = true }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = true }))

-- Cycle workspaces
hl.bind(mainMod  .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod  .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(hyperKey .. " + minus",      hl.dsp.focus({ workspace = "e-1" }))
hl.bind(hyperKey .. " + equal",      hl.dsp.focus({ workspace = "e+1" }))

-- Monitors
hl.bind(mainMod  .. " + period", hl.dsp.workspace.move({ monitor = "+1" }))
hl.bind(hyperKey .. " + period", hl.dsp.exec_cmd("~/.config/scripts/toggle-workspaces-monitors.sh"))
-- hl.bind(mainMod .. " + comma",         hl.dsp.focus({ monitor = "-1" }))
-- hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.workspace.move({ monitor = "-1" }))
