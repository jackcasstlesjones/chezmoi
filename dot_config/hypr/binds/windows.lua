local v = require("config.vars")
local mainMod, hyperKey = v.mainMod, v.hyperKey

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + Z", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))  -- dwindle
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("~/.config/scripts/move-to-workspace.sh"))

hl.bind(hyperKey .. " + Return", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(hyperKey .. " + A",      hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))

-- Close every window on the active workspace.
-- Was a `hyprctl clients | jq | xargs hyprctl dispatch closewindow` pipeline.
hl.bind(mainMod .. " + SHIFT + Q", function()
    local ws = hl.get_active_workspace()
    if ws == nil then return end
    for _, w in ipairs(hl.get_workspace_windows(ws.id)) do
        hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
        hl.dispatch(hl.dsp.window.close())
    end
end)

-- Float + pin the active window (stays visible on all workspaces), or undo that.
-- Was a `hyprctl activewindow | jq | hyprctl --batch` pipeline.
hl.bind(hyperKey .. " + P", function()
    local w = hl.get_active_window()
    if w == nil then return end
    if w.pinned then
        hl.dispatch(hl.dsp.window.pin({ action = "toggle" }))
        hl.dispatch(hl.dsp.window.float({ action = "unset" }))
    else
        hl.dispatch(hl.dsp.window.float({ action = "set" }))
        hl.dispatch(hl.dsp.window.pin({ action = "toggle" }))
    end
end)

-- Navigate between windows with hyperkey + vim keys
hl.bind(hyperKey .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(hyperKey .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(hyperKey .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(hyperKey .. " + l", hl.dsp.focus({ direction = "right" }))

-- Swap windows with hyperkey + arrow keys
hl.bind(hyperKey .. " + left",  hl.dsp.window.swap({ direction = "left" }))
hl.bind(hyperKey .. " + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(hyperKey .. " + up",    hl.dsp.window.swap({ direction = "up" }))
hl.bind(hyperKey .. " + down",  hl.dsp.window.swap({ direction = "down" }))

-- Resize the active window with super + vim motions
hl.bind(mainMod .. " + h", hl.dsp.window.resize({ x = -50, y =   0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + l", hl.dsp.window.resize({ x =  50, y =   0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + k", hl.dsp.window.resize({ x =   0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + j", hl.dsp.window.resize({ x =   0, y =  50, relative = true }), { repeating = true })

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Swallow middle-click on the touchpad (was a bind nested in input:touchpad)
hl.bind("mouse:274", hl.dsp.no_op())
