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

-- Strata always opens as a floating window
hl.window_rule({
    match = { class = "^(io\\.github\\.lgse\\.Strata)$" },
    float = true,
    center = true,
    size = "1200 800",
})

-- Floating dialogs / utilities
hl.window_rule({
    match = { class = "^(nm-connection-editor)$" },
    float = true,
})
