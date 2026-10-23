-- Shared variables for Hyprland Lua config
local M = {}

M.terminal = "uwsm app -- ghostty"
M.browser = "uwsm app -- brave-origin"
M.filemanager = "uwsm app -- ghostty --gtk-single-instance=false --title=Yazi -e yazi"
M.ipc = "noctalia msg "

return M
