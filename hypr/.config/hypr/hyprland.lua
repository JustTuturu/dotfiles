-- ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗
-- ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗
-- ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║
-- ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║
-- ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝
-- ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝
--------------------------------------------------------------------
-- Hyprland 0.55+ Lua Config

-- 1. Environment variables
require("conf.environment")

-- 2. Colors (Matugen-generated, manual Lua conversion)
require("conf.colors")

-- 3. Display / monitors
require("conf.monitors")

-- 4. Programs (MUST come before keybinding)
local vars = require("conf.vars")

-- 5. Input
require("conf.input")

-- 6. Animations
require("conf.animations")

-- 7. Appearance / colors
require("conf.appearance")

-- 8. Layout
require("conf.layout")

-- 9. Keybindings (uses vars.terminal, vars.browser, etc.)
require("conf.keybinding")

-- 10. Window rules
require("conf.windowrule")

-- 11. Miscellaneous
require("conf.misc")

-- 12. Autostart
require("conf.autostart")

-- 13. Workspace-specific rules
require("conf.workspaces")

-- 14. Noctalia settings
require("conf.noctalia")
