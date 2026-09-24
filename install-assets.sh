#!/usr/bin/env bash
# install-assets.sh — Fonts, icons, cursors, and desktop defaults
#
# Run AFTER install-system.sh.
#
# Usage:
#   ./install-assets.sh         Install fonts, Tela icons, and cursors
#   ./install-assets.sh icons   Install only Tela icons and set the icon theme
#   ./install-assets.sh fonts   Install only the configured fonts
#   ./install-assets.sh cursors Install only cursor themes and set cursor defaults
#
# Fonts:
#   - JetBrains Mono (official, ligatures) — Zed IDE buffer + terminal
#     Regular + SemiBold, from download.jetbrains.com
#   - Ghostty ships its own Nerd Font-patched JetBrains Mono, so no
#     patched Nerd Font is installed
#   - Inter (UI), Literata (reading), LXGW WenKai Mono (CJK reading) and
#     Zen Kaku Gothic New (CJK UI) downloaded from upstream (no dnf/sudo)
#   - Noto Sans + Noto Sans Mono come from Fedora default fonts (no duplicate)
#   - Noto Sans CJK dropped
#
# Icons:
#   - Tela-icon-theme — GTK/app icon theme, cloned from vinceliuice/Tela-icon-theme
#
# Cursors:
#   - hyprcursor-ChisaBLZ (Hyprland native, hyprcursor format)
#   - xcursor-ChisaBLZ (X11/XCursor format, for GTK/flatpak apps)
#   - Both from the public JustTuturu/Chisa-Hyprcursor releases
#   - Persistent env vars set via Hyprland environment.conf (NOT .zshenv)
#
set -euo pipefail

# ========================== COLORS & UTILITIES ==============================
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'
MAGENTA='\e[35m'; CYAN='\e[36m'; WHITE='\e[37m'; BOLD='\e[1m'; RESET='\e[0m'

info()  { echo -e "\n  ${BLUE}[i]${RESET} ${BOLD}$*${RESET}"; }
ok()    { echo -e "  ${GREEN}[✓]${RESET} ${BOLD}$*${RESET}"; }
warn()  { echo -e "  ${YELLOW}[!]${RESET} ${BOLD}$*${RESET}"; }
fail()  { echo -e "  ${RED}[✗]${RESET} ${BOLD}$*${RESET}" && exit 1; }

cmd_exists() { command -v "$1" &>/dev/null; }

# ========================== PROGRESS HELPERS =================================
progress_spinner() {
    local label="$1"
    shift
    local tmpout; tmpout="$(mktemp)"
    local pid spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0

    "$@" >"$tmpout" 2>&1 &
    pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 10 ))
        printf "\r  %b[%b%s%b]%b %b%b   " \
            "$BLUE" "$RESET" "${spin:$i:1}" "$BLUE" "$RESET" "$BOLD" "$label"
        sleep 0.08
    done

    local rc=0
    wait "$pid" || rc=$?

    if [[ $rc -eq 0 ]]; then
        printf "\r  %b[✓]%b %b%-50s%b\n" "$GREEN" "$RESET" "$BOLD" "$label" "$RESET"
    else
        printf "\r  %b[✗]%b %b%-50s%b\n" "$RED" "$RESET" "$BOLD" "$label" "$RESET"
        if [[ -s "$tmpout" ]]; then
            sed 's/^/    /' "$tmpout"
        fi
    fi
    rm -f "$tmpout"
    return "$rc"
}

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

ICON_DIR="${HOME}/.local/share/icons"
FONT_DIR="${HOME}/.local/share/fonts"

CURSOR_SIZE=24
# Theme names must match index.theme / manifest.hl; release archives use the same names.
HYPR_CURSOR="hyprcursor-ChisaBLZ"
X_CURSOR="xcursor-ChisaBLZ"

# ========================== DOWNLOAD HELPER ===================================
# Fetch an asset from a public GitHub release (no gh CLI or auth required).
download() {
    local url="$1" out="$2"

    cmd_exists curl || fail "curl is required to download assets"

    curl -fsSL --retry 3 -o "$out" "$url"
}

# ========================== FONTS =============================================
# Official JetBrains Mono (with ligatures) for the Zed IDE. Ghostty ships its
# own Nerd Font-patched JetBrains Mono, so no patched Nerd Font is installed.
install_fonts() {
    local -a wanted=(
        JetBrainsMono-Regular.ttf
        JetBrainsMono-SemiBold.ttf
    )

    # Check if ALL wanted fonts are already present
    local missing=0
    for f in "${wanted[@]}"; do
        [[ -f "${FONT_DIR}/${f}" ]] || { missing=1; break; }
    done
    if [[ ${missing} -eq 0 ]]; then
        ok "JetBrains Mono already installed"
        return
    fi

    info "Downloading JetBrains Mono (official, with ligatures)"
    local archive="${TEMP_DIR}/JetBrainsMono.zip"

    download \
        "https://download.jetbrains.com/fonts/JetBrainsMono-2.304.zip" \
        "${archive}" \
        || fail "Failed to download JetBrains Mono"

    cmd_exists unzip || fail "unzip is required to extract JetBrains Mono"

    mkdir -p "${FONT_DIR}"

    # Official zip nests TTFs under fonts/ttf/ (non-NL = with ligatures)
    local extracted=0
    for f in "${wanted[@]}"; do
        if unzip -p "${archive}" "fonts/ttf/${f}" > "${FONT_DIR}/${f}" 2>/dev/null \
            && [[ -s "${FONT_DIR}/${f}" ]]; then
            ((extracted++)) || true
        else
            rm -f "${FONT_DIR}/${f}"
            warn "Missing from archive: ${f}"
        fi
    done

    if [[ ${extracted} -eq 0 ]]; then
        fail "No font files extracted — archive may be corrupt or format changed"
    fi

    fc-cache -f 2>/dev/null

    ok "JetBrains Mono installed (${extracted} weights)"
}

# ========================== EXTRA FONTS =======================================
# Downloaded directly from upstream (Google Fonts / GitHub); no dnf/sudo needed.
install_extra_fonts() {
    local -a files=(
        # Inter — Latin UI (variable roman + italic)
        "Inter[opsz,wght].ttf|https://raw.githubusercontent.com/google/fonts/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf"
        "Inter-Italic[opsz,wght].ttf|https://raw.githubusercontent.com/google/fonts/main/ofl/inter/Inter-Italic%5Bopsz%2Cwght%5D.ttf"
        # Literata — Latin long-form reading (variable roman + italic)
        "Literata[opsz,wght].ttf|https://raw.githubusercontent.com/google/fonts/main/ofl/literata/Literata%5Bopsz%2Cwght%5D.ttf"
        "Literata-Italic[opsz,wght].ttf|https://raw.githubusercontent.com/google/fonts/main/ofl/literata/Literata-Italic%5Bopsz%2Cwght%5D.ttf"
        # LXGW WenKai Mono — CJK reading
        "LXGWWenKaiMono-Regular.ttf|https://github.com/lxgw/LxgwWenKai/releases/latest/download/LXGWWenKaiMono-Regular.ttf"
        "LXGWWenKaiMono-Medium.ttf|https://github.com/lxgw/LxgwWenKai/releases/latest/download/LXGWWenKaiMono-Medium.ttf"
        # Zen Kaku Gothic New — CJK UI
        "ZenKakuGothicNew-Regular.ttf|https://raw.githubusercontent.com/google/fonts/main/ofl/zenkakugothicnew/ZenKakuGothicNew-Regular.ttf"
        "ZenKakuGothicNew-Medium.ttf|https://raw.githubusercontent.com/google/fonts/main/ofl/zenkakugothicnew/ZenKakuGothicNew-Medium.ttf"
        "ZenKakuGothicNew-Bold.ttf|https://raw.githubusercontent.com/google/fonts/main/ofl/zenkakugothicnew/ZenKakuGothicNew-Bold.ttf"
    )

    local missing=0 entry
    for entry in "${files[@]}"; do
        [[ -f "${FONT_DIR}/${entry%%|*}" ]] || { missing=1; break; }
    done
    if [[ ${missing} -eq 0 ]]; then
        ok "Extra fonts already installed"
        return
    fi

    info "Downloading fonts: Inter + Literata + LXGW WenKai Mono + Zen Kaku Gothic New"
    mkdir -p "${FONT_DIR}"

    local count=0 name url
    for entry in "${files[@]}"; do
        name="${entry%%|*}"
        url="${entry#*|}"
        [[ -f "${FONT_DIR}/${name}" ]] && continue

        if download "$url" "${FONT_DIR}/${name}"; then
            ((count++)) || true
        else
            warn "Failed to download ${name}"
        fi
    done

    if [[ ${count} -eq 0 ]]; then
        fail "No extra font files downloaded"
    fi

    fc-cache -f 2>/dev/null
    ok "Extra fonts installed (${count} files)"
}

# ========================== CURSORS ===========================================
install_cursors() {
    if [[ ! -t 0 ]]; then
        info "Non-interactive shell — skipping cursor install"
        return
    fi

    echo -ne "\n  Install cursor theme? [y/N] "
    read -r reply || reply=""
    if [[ ! "${reply}" =~ ^[Yy]$ ]]; then
        info "Skipping cursor install"
        return
    fi

    local -a themes=("${HYPR_CURSOR}" "${X_CURSOR}")

    for theme in "${themes[@]}"; do
        local dest="${ICON_DIR}/${theme}"

        if [[ -d "${dest}" ]]; then
            ok "${theme} already installed"
            continue
        fi

        info "Downloading ${theme} from JustTuturu/Chisa-Hyprcursor"
        local archive="${TEMP_DIR}/${theme}.tar.gz"

        if ! download \
            "https://github.com/JustTuturu/Chisa-Hyprcursor/releases/latest/download/${theme}.tar.gz" \
            "${archive}"; then
            warn "Failed to download ${theme}"
            continue
        fi

        mkdir -p "${ICON_DIR}"
        tar -xf "${archive}" -C "${ICON_DIR}" 2>/dev/null \
            || { warn "Failed to extract ${theme}"; continue; }

        # Verify extraction produced the expected theme directory
        if [[ -d "${dest}" ]]; then
            ok "${theme} → ${dest}"
        else
            warn "Extracted but expected dir not found: ${dest}"
        fi
    done
}

# ========================== ICONS =============================================
install_icons() {
    local repo="https://github.com/vinceliuice/Tela-icon-theme.git"
    local clone_dir="${TEMP_DIR}/tela-icons"

    if [[ -f "${ICON_DIR}/Tela-dark/index.theme" ]]; then
        ok "Tela icon theme already installed"
        return
    fi

    if ! cmd_exists git; then
        fail "git is not installed — required to clone Tela icons"
    fi

    progress_spinner "Installing Tela icon theme" bash -c '
        git clone --depth 1 "'"$repo"'" "'"$clone_dir"'" &&
        "'"$clone_dir"'/install.sh"
    '

    if [[ -f "${ICON_DIR}/Tela-dark/index.theme" ]]; then
        ok "Tela icon theme → ${ICON_DIR}"
    else
        fail "Tela install failed — ${ICON_DIR}/Tela-dark not found"
    fi
}

# ========================== SET DEFAULTS ======================================
set_cursor_defaults() {
    if cmd_exists hyprctl && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        if [[ -d "${ICON_DIR}/${HYPR_CURSOR}" ]]; then
            hyprctl setcursor "${HYPR_CURSOR}" "${CURSOR_SIZE}" 2>/dev/null || true
            ok "hyprctl: ${HYPR_CURSOR} (size ${CURSOR_SIZE})"
        else
            warn "Cursor theme ${HYPR_CURSOR} not found in ${ICON_DIR}, skipping hyprctl setcursor"
        fi
    fi

    if cmd_exists gsettings; then
        gsettings set org.gnome.desktop.interface cursor-theme  "${X_CURSOR}"   2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size   "${CURSOR_SIZE}" 2>/dev/null || true
        ok "gsettings: ${X_CURSOR}"
    fi

    export XCURSOR_THEME="${X_CURSOR}"
    export XCURSOR_SIZE="${CURSOR_SIZE}"
}

set_defaults() {
    info "Setting default cursor and icon theme"

    set_cursor_defaults
    set_icon_default

    if cmd_exists flatpak; then
        flatpak override --filesystem=~/.local/share/icons:ro --user 2>/dev/null || true
        ok "Flatpak: allow read access to ~/.local/share/icons"
    fi
}

set_icon_default() {
    if ! cmd_exists gsettings; then
        warn "gsettings is not installed — cannot set the icon theme"
        return
    fi

    local current
    current="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || true)"
    if [[ "${current}" == "'Tela-dark'" ]]; then
        ok "gsettings: Tela-dark already selected"
    elif gsettings set org.gnome.desktop.interface icon-theme "Tela-dark" 2>/dev/null; then
        ok "gsettings: Tela-dark"
    else
        warn "Failed to set gsettings icon theme to Tela-dark"
    fi
}

# ========================== MAIN ==============================================
case "${1:-all}" in
    all)
        install_fonts
        install_extra_fonts
        install_icons
        install_cursors
        set_defaults
        ;;
    icons)
        install_icons
        set_icon_default
        ;;
    fonts)
        install_fonts
        install_extra_fonts
        ;;
    cursors)
        install_cursors
        set_cursor_defaults
        ;;
    *)
        echo "Usage: ./install-assets.sh [icons|fonts|cursors]"
        exit 1
        ;;
esac

echo -e "\n${GREEN}${BOLD}=== Assets Installed ===${RESET}"
