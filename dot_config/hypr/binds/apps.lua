local v = require("config.vars")
local mainMod, hyperKey, terminal, fileManager = v.mainMod, v.hyperKey, v.terminal, v.fileManager

hl.bind(mainMod  .. " + I",     hl.dsp.exec_cmd(terminal))
hl.bind(mainMod  .. " + E",     hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod  .. " + M",     hl.dsp.exec_cmd("~/.local/bin/hypr-settings"))
hl.bind(mainMod  .. " + SHIFT + M", hl.dsp.exec_cmd("~/.config/scripts/system-menu.sh"))
hl.bind(mainMod  .. " + W",     hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod  .. " + space", hl.dsp.exec_cmd("fuzzel"))
hl.bind(mainMod  .. " + P",     hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod  .. " + Y",     hl.dsp.exec_cmd("wofi-calc"))
hl.bind(mainMod  .. " + C",     hl.dsp.exec_cmd("~/.config/scripts/copy-latest-download.sh"))
hl.bind(mainMod  .. " + B",     hl.dsp.exec_cmd("kitty --class=bluetui -o remember_window_size=no -o initial_window_width=600 -o initial_window_height=500 bluetui"))
hl.bind(mainMod  .. " + R",     hl.dsp.exec_cmd("~/.config/scripts/toggle-samsung-res.sh"))
hl.bind(mainMod  .. " + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(hyperKey .. " + Y",     hl.dsp.exec_cmd("~/.config/scripts/yazi-cwd.sh"))
hl.bind(hyperKey .. " + O",     hl.dsp.exec_cmd("~/.config/scripts/fuzzel-find-dir.sh"))
hl.bind(hyperKey .. " + N",     hl.dsp.exec_cmd("~/.config/scripts/scratchpad.sh"))
hl.bind(hyperKey .. " + space", hl.dsp.exec_cmd([[hyprctl clients -j | jq -e '.[] | select(.class == "calculator")' > /dev/null || kitty --class calculator -e ~/.local/bin/calc-memory]]))

-- Clipboard history
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/.config/scripts/clipboard-history.sh"))

-- Screenshots
hl.bind(hyperKey .. " + 3", hl.dsp.exec_cmd("hyprshot -m region --freeze --clipboard-only"))
hl.bind(hyperKey .. " + 5", hl.dsp.exec_cmd("hyprshot -m region --freeze --raw | tee >(wl-copy) | swappy -f -"))

-- Type characters the keyboard layout makes awkward
-- send_shortcut, not wtype: since 0.57, wtype keys pick up the held Super.
hl.bind(mainMod .. " + 1", hl.dsp.send_shortcut({ mods = "SHIFT", key = "grave" }))
hl.bind(mainMod .. " + 2", hl.dsp.send_shortcut({ mods = "", key = "grave" }))
-- £ lives on a hidden keycode in the custom us_gbp layout (dot_config/xkb).
hl.bind(mainMod .. " + 3", hl.dsp.send_shortcut({ mods = "", key = "sterling" }))
-- NOTE: `bind = $mainMod, B, exec, wtype n` was in hyprland.conf but never fired —
-- SUPER+B was already bound to bluetui above and the first match wins. Left out.

-- Hyprsunset (blue light filter)
hl.bind(mainMod .. " + U",         hl.dsp.exec_cmd("pkill hyprsunset || hyprsunset -t 2000"))
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd("hyprsunset -t 2000"))

-- Alt + hjkl as arrow keys
-- send_shortcut, not wtype: since 0.57, wtype keys pick up the held Alt.
hl.bind("ALT + h", hl.dsp.send_shortcut({ mods = "", key = "Left" }),  { repeating = true })
hl.bind("ALT + j", hl.dsp.send_shortcut({ mods = "", key = "Down" }),  { repeating = true })
hl.bind("ALT + k", hl.dsp.send_shortcut({ mods = "", key = "Up" }),    { repeating = true })
hl.bind("ALT + l", hl.dsp.send_shortcut({ mods = "", key = "Right" }), { repeating = true })

-- Disable Ctrl+T in Chrome windows
-- send_shortcut goes straight to the window, so it isn't swallowed by this bind.
hl.bind("CTRL + T", function()
    local w = hl.get_active_window()
    if w and w.class:find("chrome", 1, true) then return end
    hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "t" }))
end)

-- Right-click on the empty desktop opens a small menu (~/.local/bin/desktop-menu).
-- Non-consuming, so right-clicks over windows and the bar still reach them; the
-- menu only opens when nothing is under the cursor.
local function inside(px, py, x, y, w, h)
    return px >= x and px < x + w and py >= y and py < y + h
end

-- Close any open desktop menu the cursor isn't over.
local function close_desktop_menus(c)
    for _, w in ipairs(hl.get_windows()) do
        if w.class == "desktop-menu" and not inside(c.x, c.y, w.at.x, w.at.y, w.size.x, w.size.y) then
            hl.dispatch(hl.dsp.exec_cmd("kill " .. w.pid))
        end
    end
end

-- Left-click outside the menu closes it (clicking bare desktop doesn't move focus,
-- so the menu can't notice by itself).
hl.bind("mouse:272", function()
    local c = hl.get_cursor_pos()
    if c then close_desktop_menus(c) end
end, { non_consuming = true })

hl.bind("mouse:273", function()
    local c = hl.get_cursor_pos()
    if c == nil then return end
    close_desktop_menus(c)
    for _, w in ipairs(hl.get_windows()) do
        if w.visible and w.mapped and not w.hidden
            and inside(c.x, c.y, w.at.x, w.at.y, w.size.x, w.size.y) then
            return
        end
    end
    for _, l in ipairs(hl.get_layers()) do
        -- 2 = top, 3 = overlay (waybar, notifications); background/bottom don't count
        if l.mapped and l.layer >= 2 and inside(c.x, c.y, l.x, l.y, l.w, l.h) then
            return
        end
    end
    hl.dispatch(hl.dsp.exec_cmd("~/.local/bin/desktop-menu"))
end, { non_consuming = true })
