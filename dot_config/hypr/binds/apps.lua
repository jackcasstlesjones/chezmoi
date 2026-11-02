local v = require("config.vars")
local mainMod, hyperKey, terminal, fileManager = v.mainMod, v.hyperKey, v.terminal, v.fileManager

hl.bind(mainMod  .. " + I",     hl.dsp.exec_cmd(terminal))
hl.bind(mainMod  .. " + E",     hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod  .. " + M",     hl.dsp.exec_cmd("~/.config/scripts/system-menu.sh"))
hl.bind(mainMod  .. " + W",     hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod  .. " + space", hl.dsp.exec_cmd("fuzzel --hide-prompt -I"))
hl.bind(mainMod  .. " + P",     hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod  .. " + Y",     hl.dsp.exec_cmd("wofi-calc"))
hl.bind(mainMod  .. " + C",     hl.dsp.exec_cmd("/home/jack/.config/waybar/scripts/wallpaper-theme.sh"))
hl.bind(mainMod  .. " + B",     hl.dsp.exec_cmd("kitty --class=bluetui -o remember_window_size=no -o initial_window_width=600 -o initial_window_height=500 bluetui"))
hl.bind(mainMod  .. " + R",     hl.dsp.exec_cmd("~/.config/scripts/toggle-samsung-res.sh"))
hl.bind(mainMod  .. " + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(hyperKey .. " + Y",     hl.dsp.exec_cmd("kitty --class yazi-float -e yazi"))
hl.bind(hyperKey .. " + O",     hl.dsp.exec_cmd("~/.config/scripts/fuzzel-find-dir.sh"))
hl.bind(hyperKey .. " + N",     hl.dsp.exec_cmd("~/.config/scripts/scratchpad.sh"))
hl.bind(hyperKey .. " + space", hl.dsp.exec_cmd([[hyprctl clients -j | jq -e '.[] | select(.class == "calculator")' > /dev/null || kitty --class calculator -e ~/.local/bin/calc-memory]]))

-- Clipboard history
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("cliphist list | fuzzel --hide-prompt --dmenu --with-nth 2 | cliphist decode | wl-copy"))

-- Screenshots
hl.bind(hyperKey .. " + 3", hl.dsp.exec_cmd("hyprshot -m region --freeze --clipboard-only"))
hl.bind(hyperKey .. " + 5", hl.dsp.exec_cmd("hyprshot -m region --freeze --raw | tee >(wl-copy) | swappy -f -"))

-- Type characters the keyboard layout makes awkward
hl.bind(mainMod .. " + 1", hl.dsp.exec_cmd([[wtype "~"]]))
hl.bind(mainMod .. " + 2", hl.dsp.exec_cmd([[wtype '`']]))
hl.bind(mainMod .. " + 3", hl.dsp.exec_cmd([[wtype '£']]))
-- NOTE: `bind = $mainMod, B, exec, wtype n` was in hyprland.conf but never fired —
-- SUPER+B was already bound to bluetui above and the first match wins. Left out.

-- Hyprsunset (blue light filter)
hl.bind(mainMod .. " + U",         hl.dsp.exec_cmd("pkill hyprsunset || hyprsunset -t 2000"))
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd("hyprsunset -t 2000"))

-- Alt + hjkl as arrow keys
hl.bind("ALT + h", hl.dsp.exec_cmd("wtype -k Left"))
hl.bind("ALT + j", hl.dsp.exec_cmd("wtype -k Down"))
hl.bind("ALT + k", hl.dsp.exec_cmd("wtype -k Up"))
hl.bind("ALT + l", hl.dsp.exec_cmd("wtype -k Right"))

-- Disable Ctrl+T in Chrome windows
hl.bind("CTRL + T", hl.dsp.exec_cmd([[hyprctl activewindow -j | jq -e '.class | contains("chrome")' > /dev/null || wtype -M ctrl -k t]]))
