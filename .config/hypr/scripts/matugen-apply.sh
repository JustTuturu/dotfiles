#!/usr/bin/env bash
# matugen-apply.sh — Apply wallpaper, generate colors, reload all apps
#
# Usage:
#   matugen-apply.sh <wallpaper_path>
#   matugen-apply.sh --random [wallpaper_dir]   (picks random from dir)

set -euo pipefail

WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"

# ── Argument handling ──────────────────────────────────────────────
case "${1:-}" in
    --random)
        dir="${2:-$WALLPAPER_DIR}"
        if [ ! -d "$dir" ]; then
            echo "Error: Wallpaper directory not found: $dir" >&2
            exit 1
        fi
        WALLPAPER=$(find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n1)
        if [ -z "$WALLPAPER" ]; then
            echo "Error: No images found in $dir" >&2
            exit 1
        fi
        ;;
    ""|--help|-h)
        echo "Usage: $(basename "$0") <wallpaper_path>"
        echo "       $(basename "$0") --random [wallpaper_dir]"
        exit 0
        ;;
    *)
        WALLPAPER="$1"
        ;;
esac

if [ ! -f "$WALLPAPER" ]; then
    echo "Error: File not found: $WALLPAPER" >&2
    exit 1
fi

echo "🎨 Applying: $(basename "$WALLPAPER")"

# ── 1. Set wallpaper ──────────────────────────────────────────────
if command -v swww &>/dev/null && pgrep -x swww-daemon &>/dev/null; then
    swww img "$WALLPAPER" \
        --transition-type grow \
        --transition-pos 0.5,0.5 \
        --transition-duration 1
    echo "  ✓ Wallpaper set (swww)"
else
    echo "  ⚠ swww-daemon not running — skipping wallpaper set"
fi

# ── 2. Generate matugen colors ────────────────────────────────────
matugen image "$WALLPAPER"
echo "  ✓ Colors generated"

# ── 3. Reload Hyprland (colors + border) ─────────────────────────
if command -v hyprctl &>/dev/null && hyprctl monitors &>/dev/null 2>&1; then
    # Source the generated colors into hyprland
    source_line="source = \$HOME/.config/matugen/generated/hyprland-colors.conf"
    hyprctl keyword "source" "$HOME/.config/matugen/generated/hyprland-colors.conf" &>/dev/null || true
    hyprctl reload &>/dev/null
    echo "  ✓ Hyprland reloaded"
fi

# ── 4. Quickshell — colors already written to /tmp/qs_colors.json ─
# MatugenColors.qml polls /tmp/qs_colors.json every 1s automatically.
# Nothing to do — it will pick up changes within 1 second.
echo "  ✓ Quickshell colors queued (auto-reloads within 1s)"

# ── 5. Reload Waybar ─────────────────────────────────────────────
if pgrep -x waybar &>/dev/null; then
    pkill -SIGUSR2 waybar 2>/dev/null || true
    echo "  ✓ Waybar reloaded"
fi

# ── 6. Reload Ghostty ────────────────────────────────────────────
# Ghostty doesn't support live reload of palette — new windows get new colors
echo "  ℹ Ghostty: new windows will use updated colors"

# ── 7. Notify ────────────────────────────────────────────────────
if command -v notify-send &>/dev/null; then
    notify-send "Theme Applied" "$(basename "$WALLPAPER")" \
        --icon=preferences-color \
        --urgency=low \
        --expire-time=3000 \
        2>/dev/null || true
fi

echo ""
echo "✅ Done!"
