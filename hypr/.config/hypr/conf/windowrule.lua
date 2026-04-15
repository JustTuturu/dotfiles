-- Window rules

-- No blur for brave
hl.window_rule({
    match = { class = "brave-browser" },
    no_blur = true,
})

-- Floating dialogs / utilities
hl.window_rule({
    match = { class = "^(pavucontrol|blueman-manager|nm-connection-editor|gnome-calculator|qalculate-gtk)$" },
    float = true,
})
hl.window_rule({
    match = { class = "^(Lxappearance|qt5ct|qt6ct|kvantummanager|org.kde.systemsettings)$" },
    float = true,
})
-- Steam: only float dialogs/popups, keep main window tiled
hl.window_rule({
    match = { class = "^(Steam)$", title = "negative:^(Steam)$" },
    float = true,
})
