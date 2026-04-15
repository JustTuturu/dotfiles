-- Workspace rules
--
-- Persistent workspaces keep empty workspaces visible in Noctalia v5's
-- workspace switcher (instead of only showing ones with windows).
-- Layout: workspaces 1-5 on HDMI-A-1 (left), 6-10 on DP-2 (right).

-- HDMI-A-1 (left, 2560x1440@100) — default
hl.workspace_rule({
    workspace = "1",
    monitor = "HDMI-A-1",
    default = true,
    persistent = true,
    default_name = "1",
})

hl.workspace_rule({
    workspace = "2",
    monitor = "DP-2",
    persistent = true,
    default_name = "2",
})
