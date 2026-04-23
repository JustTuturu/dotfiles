#!/usr/bin/env bash
# install-assets.sh — Cài fonts + cursor themes
# Fonts  → ~/.local/share/fonts
# Cursor → ~/.local/share/icons

set -euo pipefail

# ========================== COLORS ===========================================
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'; BOLD='\e[1m'; RESET='\e[0m'

info() { echo -e "\n  ${BLUE}[i]${RESET} ${BOLD}$*${RESET}"; }
ok()   { echo -e "  ${GREEN}[✓]${RESET} ${BOLD}$*${RESET}"; }
warn() { echo -e "  ${YELLOW}[!]${RESET} ${BOLD}$*${RESET}"; }
fail() { echo -e "  ${RED}[✗]${RESET} ${BOLD}$*${RESET}"; exit 1; }

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

# ========================== CONFIG ===========================================
REPO_OWNER="JustTuturu"
REPO_NAME="TuturuCursor"
BASE_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest/download"

HYPR_CURSOR="HChisaBLZ"
X_CURSOR="XChisaBLZ"
CURSOR_SIZE=24

ICON_DIR="${HOME}/.local/share/icons"
FONT_DIR="${HOME}/.local/share/fonts"

# ========================== AUTH =============================================
get_token() {
    local token="${GH_TOKEN:-}"
    if [[ -z "${token}" ]]; then
        echo -e "\n  ${YELLOW}[!]${RESET} Repo private — cần GitHub token" >&2
        echo -e "  ${BLUE}[i]${RESET} Tạo tại: https://github.com/settings/tokens (scope: repo)" >&2
        read -rsp "  Nhập GitHub Token: " token
        echo >&2
    fi
    [[ -z "${token}" ]] && fail "Không có token — huỷ"
    echo "${token}"
}

gh_download() {
    local url="$1" dest="$2" token="$3"
    curl -fsSL \
        -H "Authorization: Bearer ${token}" \
        -L "${url}" -o "${dest}"
}

# ========================== FONTS ============================================
install_fonts() {
    mkdir -p "${FONT_DIR}"

    if fc-list | grep -qi "JetBrainsMono.*Nerd Font"; then
        ok "JetBrains Mono Nerd Font đã có sẵn"
        return
    fi

    info "Tải JetBrains Mono Nerd Font"
    local archive="${TEMP_DIR}/JetBrainsMono.tar.xz"
    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" \
        -o "${archive}"

    tar -xf "${archive}" -C "${TEMP_DIR}" --wildcards \
        "JetBrainsMonoNerdFont-Regular.ttf" \
        "JetBrainsMonoNerdFont-Bold.ttf" \
        "JetBrainsMonoNerdFont-BoldItalic.ttf" \
        "JetBrainsMonoNerdFontMono-Regular.ttf" \
        "JetBrainsMonoNerdFontMono-Bold.ttf" \
        "JetBrainsMonoNerdFontMono-BoldItalic.ttf" \
        2>/dev/null || true

    find "${TEMP_DIR}" -maxdepth 1 -name "*.ttf" -exec mv -f {} "${FONT_DIR}/" \;
    fc-cache -f "${FONT_DIR}" &>/dev/null
    ok "JetBrains Mono NF + NFM đã cài"
}

# ========================== CURSORS ==========================================
install_cursor() {
    local name="$1" token="$2"
    local dest="${ICON_DIR}/${name}"

    if [[ -d "${dest}" ]]; then
        ok "${name} đã có sẵn, bỏ qua"
        return
    fi

    info "Tải ${name}"
    local archive="${TEMP_DIR}/${name}.tar.gz"
    gh_download "${BASE_URL}/${name}.tar.gz" "${archive}" "${token}"

    mkdir -p "${ICON_DIR}"
    tar -xf "${archive}" -C "${ICON_DIR}"
    ok "${name} → ${dest}"
}

# ========================== SET DEFAULTS =====================================
set_defaults() {
    info "Thiết lập cursor mặc định"

    # Hyprland — hyprcursor native
    if command -v hyprctl &>/dev/null; then
        hyprctl setcursor "${HYPR_CURSOR}" "${CURSOR_SIZE}" 2>/dev/null || true
        ok "hyprctl: ${HYPR_CURSOR} (size ${CURSOR_SIZE})"
    fi

    # GTK — xcursor fallback
    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface cursor-theme "${X_CURSOR}" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size "${CURSOR_SIZE}" 2>/dev/null || true
        ok "gsettings: ${X_CURSOR}"
    fi

    # XCURSOR env cho XWayland
    local zshenv="${HOME}/.zshenv"
    if [[ -f "${zshenv}" ]] && grep -q "XCURSOR_THEME" "${zshenv}"; then
        sed -i \
            -e "s|export XCURSOR_THEME=.*|export XCURSOR_THEME=${X_CURSOR}|" \
            -e "s|export XCURSOR_SIZE=.*|export XCURSOR_SIZE=${CURSOR_SIZE}|" \
            "${zshenv}"
        ok "Cập nhật XCURSOR_* trong ~/.zshenv"
    else
        printf "\nexport XCURSOR_THEME=%s\nexport XCURSOR_SIZE=%s\n" \
            "${X_CURSOR}" "${CURSOR_SIZE}" >> "${zshenv}"
        ok "Thêm XCURSOR_* vào ~/.zshenv"
    fi

    # Flatpak
    if command -v flatpak &>/dev/null; then
        flatpak override --filesystem=~/.local/share/icons:ro --user 2>/dev/null || true
        ok "Flatpak: cho phép đọc ~/.local/share/icons"
    fi
}

# ========================== MAIN =============================================
install_fonts

TOKEN="$(get_token)"
install_cursor "${HYPR_CURSOR}" "${TOKEN}"
install_cursor "${X_CURSOR}" "${TOKEN}"

set_defaults

echo -e "\n  ${GREEN}${BOLD}✓ Xong! Đăng xuất và đăng nhập lại để áp dụng cursor.${RESET}\n"