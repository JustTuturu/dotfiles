-- Keybindings
local vars = require("conf.vars")
local mainMod = "SUPER"
local ipc = vars.ipc

-- ═══════════════════════════════════════════════════════════════════
-- Application launchers
-- ═══════════════════════════════════════════════════════════════════
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(vars.terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(vars.browser))
hl.bind(mainMod .. " + 9", hl.dsp.exec_cmd(vars.browser .. " http://localhost:20128/dashboard"))
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd(vars.terminal .. " -e yazi"))

-- ═══════════════════════════════════════════════════════════════════
-- Noctalia integration
-- ═══════════════════════════════════════════════════════════════════
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(ipc .. "volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(ipc .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(ipc .. "volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. "brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. "brightness-down"), { locked = true, repeating = true })

hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(ipc .. "panel-toggle control-center"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(ipc .. "settings-toggle"))
hl.bind("ALT + Tab", hl.dsp.exec_cmd(ipc .. "window-switcher"))

-- ═══════════════════════════════════════════════════════════════════
-- Window management
-- ═══════════════════════════════════════════════════════════════════
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + C", hl.dsp.window.center())
hl.bind(mainMod .. " + SHIFT + C", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.center())
end)
hl.bind(mainMod .. " + P", hl.dsp.window.pin())

-- ── Scratch terminal (SUPER+Escape) ───────────────────────────────
-- Native Lua toggle on special workspace scratch
hl.bind(mainMod .. " + Escape", function()
    local scratch_wins = hl.get_workspace_windows("special:scratch")
    if scratch_wins and #scratch_wins > 0 then
        hl.dispatch(hl.dsp.workspace.toggle_special("scratch"))
    else
        hl.dispatch(hl.dsp.exec_cmd(vars.terminal, { workspace = "special:scratch" }))
        hl.dispatch(hl.dsp.workspace.toggle_special("scratch"))
    end
end)

-- Swap windows
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.swap({ direction = "d" }))

-- ═══════════════════════════════════════════════════════════════════
-- Focus navigation
-- ═══════════════════════════════════════════════════════════════════
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

-- ═══════════════════════════════════════════════════════════════════
-- Workspaces (persistent 1-10)
-- ═══════════════════════════════════════════════════════════════════
hl.bind(mainMod .. "+SHIFT+1", hl.dsp.window.move({ workspace = "1" }))
hl.bind(mainMod .. "+SHIFT+2", hl.dsp.window.move({ workspace = "2" }))

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- ═══════════════════════════════════════════════════════════════════
-- Layout controls
-- ═══════════════════════════════════════════════════════════════════
hl.bind(mainMod .. " + Z", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.layout("swapsplit"))

-- ═══════════════════════════════════════════════════════════════════
-- Mouse bindings
-- ═══════════════════════════════════════════════════════════════════
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ═══════════════════════════════════════════════════════════════════
-- Screenshots
-- ═══════════════════════════════════════════════════════════════════
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("uwsm app -- grimblast --notify copy area"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("uwsm app -- grimblast --notify copy screen"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("uwsm app -- grimblast --notify copy output"))

-- ═══════════════════════════════════════════════════════════════════
-- Session controls
-- ═══════════════════════════════════════════════════════════════════
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("uwsm app -- hyprlock"))
hl.bind(mainMod .. " + SHIFT + F12", hl.dsp.exit())

-- ═══════════════════════════════════════════════════════════════════
-- Function keys (media)
-- ═══════════════════════════════════════════════════════════════════
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })
