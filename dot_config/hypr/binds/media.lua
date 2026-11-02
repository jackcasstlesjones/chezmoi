local v = require("config.vars")
local mainMod, hyperKey = v.mainMod, v.hyperKey

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"),          { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"),          { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),    { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("swayosd-client --brightness raise"),             { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("swayosd-client --brightness lower"),             { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

hl.bind(hyperKey .. " + Q",   hl.dsp.exec_cmd("playerctl -p spotify play-pause"))
hl.bind(hyperKey .. " + tab", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("SHIFT + ALT + space", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind(mainMod .. " + left",  hl.dsp.exec_cmd("playerctl -p spotify previous"))
hl.bind(mainMod .. " + right", hl.dsp.exec_cmd("playerctl -p spotify next"))

-- Volume with super + alt + arrows, and hyperkey + 1/2
hl.bind(mainMod  .. " + ALT + up",   hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })
hl.bind(mainMod  .. " + ALT + down", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind(hyperKey .. " + 1",          hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind(hyperKey .. " + 2",          hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true })

-- SK75 keyboard volume controls (device-scoped; was a `device { bindel = ... }` block)
local sk75 = { inclusive = true, list = { "telink-wireless-gaming-keyboard" } }
hl.bind("F11", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true, device = sk75 })
hl.bind("F12", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { locked = true, repeating = true, device = sk75 })

-- Clamshell mode: disable/enable the laptop screen when the lid closes/opens
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("~/.config/scripts/lid.sh open"),  { locked = true })
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("~/.config/scripts/lid.sh close"), { locked = true })
