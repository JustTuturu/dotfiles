-- Bezier curves
hl.curve("easeOutQuint", { type = "bezier", points = { {0.22, 1}, {0.36, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0}, {0.35, 1} } })
hl.curve("smoothIn", { type = "bezier", points = { {0.2, 1}, {0.2, 1} } })
hl.curve("smoothOut", { type = "bezier", points = { {0.2, 1}, {0.2, 1} } })

-- Animations
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "easeInOutCubic", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "easeInOutCubic" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "smoothOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "easeInOutCubic", style = "slide" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "smoothOut", style = "slide" })
hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })
