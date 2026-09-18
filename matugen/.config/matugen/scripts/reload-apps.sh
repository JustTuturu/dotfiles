#!/usr/bin/env bash
# reload-apps.sh — nudge the apps that do NOT re-read their theme file on change.
#
# Called at the end of every matugen render (wallpaper-hook.sh). Safe to run by
# hand after a manual `matugen image ...`. Every step is a no-op when its app is
# not running, and the script never exits non-zero because a nudge failed: a
# failed reload must not mark the render as failed.
#
# Why these three and nothing else:
#   ghostty  — does not reload its config on change (its man page for
#              +edit-config is explicit). Launched via uwsm it runs as a systemd
#              user unit, so `systemctl --user reload` is the supported path;
#              instances owning no unit get SIGUSR2. Same strategy as Noctalia's
#              built-in ghostty template.
#   btop     — reads its theme file at startup; SIGUSR2 is its reload signal.
#              Same as Noctalia's built-in btop template.
#   hyprland — reads ~/.config/hypr/generated/colors.lua while parsing its
#              config, so it genuinely needs a reload. Noctalia does not do this
#              — there is no hyprctl call anywhere in the binary.
#
# Everything else follows on its own: zsh / fzf / starship / eza on next use,
# bat when it next runs, hyprlock when it next locks, and Noctalia's own UI and
# greeter through Noctalia itself.
set -euo pipefail

log() { printf '[%s] matugen-reload: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

reload_ghostty() {
    local unit="app-com.mitchellh.ghostty.service" pid="" pids=""

    if command -v systemctl >/dev/null 2>&1; then
        pid="$(systemctl --user show --property=MainPID --value "$unit" 2>/dev/null || true)"
    fi

    if [[ "$pid" =~ ^[1-9][0-9]*$ ]] && systemctl --user reload "$unit" >/dev/null 2>&1; then
        log "ghostty: reloaded via systemd (pid ${pid})"
        return 0
    fi

    # Units aside, SIGUSR2 is ghostty's reload signal.
    pids="$(pgrep -x ghostty 2>/dev/null || true)"
    if [ -n "$pids" ]; then
        # shellcheck disable=SC2086
        if kill -SIGUSR2 $pids 2>/dev/null; then
            log "ghostty: SIGUSR2 sent to $(printf '%s\n' $pids | wc -l) instance(s)"
        else
            log "ghostty: could not signal $(printf '%s\n' $pids | tr '\n' ' ')"
        fi
        return 0
    fi

    log "ghostty: not running"
}

reload_btop() {
    if pgrep -x btop >/dev/null 2>&1; then
        if pkill -SIGUSR2 -x btop 2>/dev/null; then
            log "btop: reloaded (SIGUSR2)"
        else
            log "btop: SIGUSR2 failed"
        fi
    else
        log "btop: not running"
    fi
}

reload_hyprland() {
    if ! command -v hyprctl >/dev/null 2>&1; then
        log "hyprland: hyprctl not found"
        return 0
    fi
    if hyprctl reload >/dev/null 2>&1; then
        log "hyprland: reloaded"
    else
        log "hyprland: hyprctl reload failed (no compositor in this environment?)"
    fi
}

reload_ghostty
reload_btop
reload_hyprland

exit 0
