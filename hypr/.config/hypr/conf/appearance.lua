local colors = require("conf.colors")

hl.config({
    general = {
        border_size = 2,
        col = {
            active_border   = { colors = { colors.accent, colors.accentAlt }, angle = 45 },
            inactive_border = colors.bgAlt,
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        active_opacity = 1.0,
        inactive_opacity = 1.0,
    },
})
