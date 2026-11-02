-- Pin workspace 4 to the Lenovo monitor
hl.workspace_rule({ workspace = "name:4", monitor = "desc:Lenovo Group Limited T24m-10 VTG73855" })

-- "Smart gaps" / "no gaps when only" — uncomment all if you want it
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ name = "no-gaps-f1",   match = { float = false, workspace = "f[1]"   }, border_size = 0, rounding = 0 })
