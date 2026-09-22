-- Workspace rules
--
-- Persistent workspaces keep empty workspaces visible in Noctalia v5's
-- workspace switcher (instead of only showing ones with windows).
-- Layout: workspaces 1-7 on HDMI-A-1 (left), 8-14 on DP-2 (right).

-- HDMI-A-1 (left, 2560x1440@100) — default
for i = 1, 3 do
    local rule = {
        workspace    = tostring(i),
        monitor      = "HDMI-A-1",
        persistent   = true,
        default_name = tostring(i),
    }
    if i == 1 then
        rule.default = true
    end
    hl.workspace_rule(rule)
end

-- DP-2 (right, 2560x1440@200)
for i = 4, 6 do
    hl.workspace_rule({
        workspace    = tostring(i),
        monitor      = "DP-2",
        persistent   = true,
        default_name = tostring(i),
    })
end
