-- Autostart
hl.on("hyprland.start", function()
    -- ============================================
    -- Noctalia Shell (v5 native)
    -- ============================================
    hl.exec_cmd("noctalia")

    -- Noctalia handles notifications natively; no separate daemon needed
    -- hl.exec_cmd("swaync")

    -- NetworkManager tray applet
    hl.exec_cmd("nm-applet --indicator")

    -- ============================================
    -- Input method
    -- ============================================
    hl.exec_cmd("fcitx5 -d --replace")

    -- ============================================
    -- Screen sharing — XDG portals (critical on Fedora)
    -- ============================================
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprland-session.service")
    hl.exec_cmd("systemctl --user restart xdg-desktop-portal-hyprland")
    hl.exec_cmd("systemctl --user restart xdg-desktop-portal-gtk")
    hl.exec_cmd("systemctl --user restart xdg-desktop-portal")

    -- ============================================
    -- Clipboard
    -- ============================================
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- ============================================
    -- Idle management — lock & sleep
    -- ============================================
    hl.exec_cmd("systemctl --user restart hypridle.service")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)
