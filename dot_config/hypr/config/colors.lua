-- pywal colours, parsed from ~/.cache/wal/colors-hyprland.conf.
-- hyprlang did `source = ~/.cache/wal/colors-hyprland.conf` and used $color11 etc.
-- Lua can't `require` a hyprlang file, so parse it. Falls back to the Nord
-- values pywal currently generates if the cache file is missing.
local function load_wal_colors()
    local defaults = {
        foreground = "rgba(d8dee9ff)",
        background = "rgba(2e3440ff)",
        color8     = "rgba(4c566aff)",
        color11    = "rgba(ebcb8bff)",
    }

    local colors = {}
    local f = io.open(os.getenv("HOME") .. "/.cache/wal/colors-hyprland.conf", "r")
    if f then
        for line in f:lines() do
            local name, value = line:match("^%s*%$([%w_]+)%s*=%s*(%S+)")
            if name then colors[name] = value end
        end
        f:close()
    end

    return setmetatable(colors, { __index = defaults })
end

return load_wal_colors()
