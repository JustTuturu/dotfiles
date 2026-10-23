#!/usr/bin/env bash
# wallpaper-hook.sh — run matugen when Noctalia's wallpaper_changed hook fires.
#
# This is the ONLY thing that re-renders the matugen templates. Noctalia's own
# template rendering is disabled (no builtin_ids / community_ids) and no other
# Noctalia hook (colors_changed, theme_mode_changed) is configured, so the
# palette changes exactly when the wallpaper changes.
#
# Why a wrapper instead of the one-liner in config.toml:
#   * Noctalia fires wallpaper_changed once per output connector, so one
#     wallpaper change on a two-monitor setup arrives as two events ~30 ms
#     apart. flock serialises them and the stamp file makes the duplicate a
#     no-op, so matugen runs once per real change instead of twice.
#   * It survives an empty NOCTALIA_WALLPAPER_PATH (the docs note the value is
#     not tied to a live connector in some cases) instead of failing matugen.
#
# Reads NOCTALIA_WALLPAPER_PATH / NOCTALIA_WALLPAPER_CONNECTOR from the hook
# environment; no arguments.
set -euo pipefail

log() { printf '[%s] matugen-wallpaper-hook: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }

img="${NOCTALIA_WALLPAPER_PATH:-}"
connector="${NOCTALIA_WALLPAPER_CONNECTOR:-}"

if [ -z "$img" ]; then
    log "no NOCTALIA_WALLPAPER_PATH in the hook environment; nothing to do"
    exit 0
fi
if [ ! -f "$img" ]; then
    log "ERROR: wallpaper not found: $img"
    exit 1
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/matugen"
stamp="$state_dir/last-wallpaper"
lock="$state_dir/wallpaper-hook.lock"
mkdir -p "$state_dir"

# Serialise: the second connector's event waits here until the first finishes,
# so the two matugen runs never write the same files concurrently.
exec 9>"$lock"
flock 9

if [ -r "$stamp" ] && [ "$(<"$stamp")" = "$img" ]; then
    log "connector=${connector:-none}: already rendered $img; skipping duplicate event"
    exit 0
fi

log "connector=${connector:-none}: rendering $img"
matugen image "$img" --prefer darkness
printf '%s\n' "$img" >"$stamp"
log "rendered $img"

# Nudge the apps that do not re-read their own config (ghostty, btop,
# hyprland). Never fatal: a failed reload must not fail the render.
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bash "$script_dir/reload-apps.sh" || log "WARNING: reload-apps.sh returned non-zero"
