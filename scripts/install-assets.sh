#!/usr/bin/env bash
# install-assets.sh — Download fonts + hyprcursor theme
# Fonts go to ~/.local/share/fonts
# Hyprcursor themes go to ~/.local/share/icons (per wiki.hypr.land)

set -euo pipefail

# ========================== COLORS & UTILITIES ===============================
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'; BOLD='\e[1m'; RESET='\e[0m'

info()  { echo -e "\n  ${BLUE}[i]${RESET} ${BOLD}$*${RESET}"; }
ok()    { echo -e "  ${GREEN}[✓]${RESET} ${BOLD}$*${RESET}"; }
warn()  { echo -e "  ${YELLOW}[!]${RESET} ${BOLD}$*${RESET}"; }
fail()  { echo -e "  ${RED}[✗]${RESET} ${BOLD}$*${RESET}"; }

TEMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "${TEMP_DIR}"; }
trap cleanup EXIT

# ========================== FONTS ============================================
install_fonts() {
    local font_dir="${HOME}/.local/share/fonts"
    mkdir -p "${font_dir}"

    if fc-list | grep -qi "JetBrainsMono.*Nerd Font Mono"; then
        ok "JetBrains Mono Nerd Font already installed"
    else
        info "Downloading JetBrains Mono Nerd Font"
        local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        local archive="${TEMP_DIR}/JetBrainsMono.tar.xz"

        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "${font_url}" -o "${archive}"
        elif command -v wget >/dev/null 2>&1; then
            wget -q "${font_url}" -O "${archive}"
        else
            fail "Neither curl nor wget is available"
            return 1
        fi

        mkdir -p "${TEMP_DIR}/fonts_extract"
        tar -xf "${archive}" -C "${TEMP_DIR}/fonts_extract"

        # Only keep NF (terminal) + NFM (IDE), Regular + Bold only
        find "${TEMP_DIR}/fonts_extract" -type f \( \
            -name "JetBrainsMonoNerdFont-Regular.ttf" \
            -o -name "JetBrainsMonoNerdFont-Bold.ttf" \
            -o -name "JetBrainsMonoNerdFont-BoldItalic.ttf" \
            -o -name "JetBrainsMonoNerdFontMono-Regular.ttf" \
            -o -name "JetBrainsMonoNerdFontMono-Bold.ttf" \
            -o -name "JetBrainsMonoNerdFontMono-BoldItalic.ttf" \
        \) -exec mv -f {} "${font_dir}/" \;

        fc-cache -f "${font_dir}" >/dev/null 2>&1 || fc-cache -f >/dev/null 2>&1
        ok "JetBrains Mono NF + NFM installed"
    fi
}

# ========================== HYPRCURSOR ========================================
install_cursor() {
    local cursor_name="ChisaBLZ"
    local cursor_dir="${HOME}/.local/share/icons/${cursor_name}"

    # ── CONFIG: Set your GitHub release URL here ──
    # Supports: .tar.gz, .tar.xz, .zip archives containing the theme folder
    # Example: https://github.com/YOUR_USER/YOUR_REPO/releases/latest/download/ChisaBLZ.tar.gz
    local cursor_url="${CURSOR_URL:-}"
    # ───────────────────────────────────────────────

    if [ -d "${cursor_dir}" ] && [ -f "${cursor_dir}/manifest.hl" ]; then
        ok "${cursor_name} hyprcursor theme already installed"
        return 0
    fi

    # If no URL configured, skip with instructions
    if [ -z "${cursor_url}" ]; then
        warn "No CURSOR_URL set. Manual install:"
        warn "  1. Create a GitHub release with your hyprcursor theme"
        warn "  2. Run: CURSOR_URL=https://github.com/.../ChisaBLZ.tar.gz ./install-assets.sh"
        warn "  Or copy ${cursor_name}/ to ${cursor_dir}/ manually"
        return 0
    fi

    info "Downloading ${cursor_name} hyprcursor theme"
    local archive="${TEMP_DIR}/${cursor_name}.tar.gz"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "${cursor_url}" -o "${archive}"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "${cursor_url}" -O "${archive}"
    else
        fail "Neither curl nor wget is available"
        return 1
    fi

    # Extract and find the theme directory containing manifest.hl
    mkdir -p "${TEMP_DIR}/cursor_extract"
    tar -xf "${archive}" -C "${TEMP_DIR}/cursor_extract" 2>/dev/null \
        || unzip -q "${archive}" -d "${TEMP_DIR}/cursor_extract" 2>/dev/null

    local theme_dir
    theme_dir="$(find "${TEMP_DIR}/cursor_extract" -name "manifest.hl" -printf '%h' | head -1)"

    if [ -z "${theme_dir}" ]; then
        fail "No manifest.hl found in archive — is this a valid hyprcursor theme?"
        return 1
    fi

    mkdir -p "$(dirname "${cursor_dir}")"
    cp -r "${theme_dir}" "${cursor_dir}"
    ok "${cursor_name} hyprcursor theme installed to ${cursor_dir}"
}

# ========================== SET DEFAULTS =====================================
set_defaults() {
    local cursor_name="${1:-ChisaBLZ}"
    local cursor_size=24

    info "Setting ${cursor_name} as default cursor"

    # hyprctl setcursor — sets cursor for Hyprland + Qt/Electron
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl setcursor "${cursor_name}" "${cursor_size}" 2>/dev/null || true
    fi

    # gsettings — sets cursor for GTK apps
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface cursor-theme "${cursor_name}" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size "${cursor_size}" 2>/dev/null || true
    fi

    # XCURSOR_THEME — fallback for X11 / non-hyprcursor apps
    # Write to .zshenv so it's always available
    local zshenv="${HOME}/.zshenv"
    if [ -f "${zshenv}" ] && ! grep -q "XCURSOR_THEME" "${zshenv}"; then
        echo -e "\nexport XCURSOR_THEME=${cursor_name}\nexport XCURSOR_SIZE=${cursor_size}" >> "${zshenv}"
        ok "Added XCURSOR_THEME to ~/.zshenv"
    elif [ -f "${zshenv}" ] && grep -q "XCURSOR_THEME" "${zshenv}"; then
        sed -i "s/export XCURSOR_THEME=.*/export XCURSOR_THEME=${cursor_name}/" "${zshenv}"
        sed -i "s/export XCURSOR_SIZE=.*/export XCURSOR_SIZE=${cursor_size}/" "${zshenv}"
        ok "Updated XCURSOR_THEME in ~/.zshenv"
    fi

    # Flatpak cursor access
    if command -v flatpak >/dev/null 2>&1; then
        flatpak override --filesystem=~/.icons:ro --user 2>/dev/null || true
        flatpak override --filesystem=~/.local/share/icons:ro --user 2>/dev/null || true
        ok "Flatpak cursor access configured"
    fi

    ok "${cursor_name} set as default cursor"
}

# ========================== MAIN =============================================
# ========================== MAIN =============================================
install_fonts

# Cài đặt Hyprcursor
HYPR_URL="https://github.com/JustTuturu/TuturuCursor/releases/latest/download/ChisaBLZ.tar.gz"
install_cursor "ChisaBLZ" "${HYPR_URL}"

# Cài đặt XCursor (Dùng cho các app cũ/XWayland)
XCUR_URL="https://github.com/JustTuturu/TuturuCursor/releases/latest/download/XChisaBLZ.tar.gz"
install_cursor "XChisaBLZ" "${XCUR_URL}"

# Thiết lập mặc định (Ưu tiên Hyprcursor cho Hyprland)
set_defaults "ChisaBLZ" "XChisaBLZ"