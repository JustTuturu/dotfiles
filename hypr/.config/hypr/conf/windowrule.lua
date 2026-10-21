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

-- Floating dialogs / utilities
hl.window_rule({
    match = { class = "^(nm-connection-editor)$" },
    float = true,
})
