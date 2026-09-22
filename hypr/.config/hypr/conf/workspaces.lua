-- Workspace rules
for i = 1, 3 do
    local rule = {
        workspace    = tostring(i),
        monitor      = "HDMI-A-1",
        persistent   = true,
        default_name = tostring(i),
    }
    hl.workspace_rule(rule)
end

-- DP-2 (right, 2560x1440@200)
for i = 4, 6 do
    local rule = {
        workspace    = tostring(i),
        monitor      = "DP-2",
        persistent   = true,
        default_name = tostring(i),
    }
    if i == 4 then
        rule.default = true
    end
    hl.workspace_rule(rule)
end
