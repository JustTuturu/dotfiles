-- Autostart
hl.on("hyprland.start", function()
    -- Tell UWSM that the compositor has finished publishing its session
    -- environment before starting session applications.
    hl.exec_cmd("uwsm finalize XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE")

    -- ============================================
    -- Noctalia Shell (v5 native)
    -- ============================================
    -- Force Noctalia to use hyprqt6engine for Qt6 theming.
    hl.exec_cmd("uwsm app -- env QT_QPA_PLATFORMTHEME=hyprqt6engine noctalia")

    -- Noctalia handles notifications natively; no separate daemon needed
    -- hl.exec_cmd("swaync")

    -- NetworkManager tray applet
    hl.exec_cmd("uwsm app -- nm-applet --indicator")

    -- ============================================
    -- Input method
    -- ============================================
    hl.exec_cmd("uwsm app -- fcitx5 -d --replace")

    -- ============================================
    -- ============================================
    -- Clipboard
    -- ============================================
    hl.exec_cmd("uwsm app -- wl-paste --type text --watch cliphist store")
    hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist store")

    -- ============================================
    -- Idle management — lock & sleep
    -- ============================================
    hl.exec_cmd("systemctl --user restart hypridle.service")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)
