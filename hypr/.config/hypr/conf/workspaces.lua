-- Workspace rules

-- HDMI-A-1 (left, 2560x1440@100)
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", persistent = true, default_name = "1" })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", persistent = true, default_name = "2" })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1", persistent = true, default_name = "3" })

-- DP-2 (right, 2560x1440@200)
hl.workspace_rule({ workspace = "4", monitor = "DP-2", persistent = true, default_name = "4" })
hl.workspace_rule({ workspace = "5", monitor = "DP-2", persistent = true, default_name = "5" })
hl.workspace_rule({ workspace = "6", monitor = "DP-2", persistent = true, default_name = "6" })
