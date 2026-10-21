-- Window rules

-- No blur for brave
hl.window_rule({
    match = { class = "^(brave-origin|brave-browser)$" },
    no_blur = true,
})

-- Keep Spotify on its own workspace
hl.window_rule({
    match = { class = "^(spotifast)$" },
    workspace = "3",
})

-- Yazi opens in its own floating Ghostty window.
hl.window_rule({
    match = { class = "^(com\\.mitchellh\\.ghostty)$", title = "^(Yazi)$" },
    float = true,
    center = true,
    size = "1600 900",
})

-- File chooser (xdg-desktop-portal-termfilechooser) floats like Super+E Yazi.
hl.window_rule({
    match = { class = "^(com\\.mitchellh\\.ghostty)$", title = "^(termfilechooser)$" },
    float = true,
    center = true,
    size = "1600 900",
})

-- Floating dialogs / utilities
hl.window_rule({
    match = { class = "^(nm-connection-editor)$" },
    float = true,
})
