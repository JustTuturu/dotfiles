-- Environment variables
hl.env("HYPRCURSOR_THEME", "ChisaBLZ-hypr")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "ChisaBLZ")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRLAND_CMD", "Hyprland")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- Use hyprqt6engine for all Qt6 applications, including Noctalia.
hl.env("QT_QPA_PLATFORMTHEME", "hyprqt6engine")
hl.env("QT_ICON_THEME", "Tela")

hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("INPUT_METHOD", "fcitx")
hl.env("SDL_IM_MODULE", "fcitx")

hl.env("GRIMBLAST_DIR", os.getenv("HOME") .. "/Pictures/Screenshots")

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
    ecosystem = {
        no_update_news = true,
    },
})
