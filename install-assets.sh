#!/usr/bin/env bash
# install-assets.sh — Fonts, icons, cursors, and desktop defaults
#
# Run AFTER install-system.sh.
#
# Fonts:
#   - JetBrains Mono Nerd Font (NF) — terminal/Ghostty (ligatures)
#   - JetBrains Mono Nerd Font Mono (NFM) — Zed IDE, Noctalia (no ligatures)
#   - Only Regular + Bold + Italic + BoldItalic weights (8 files total)
#   - Downloaded from ryanoasis/nerd-fonts GitHub releases (tar.xz)
#   - Noto Sans (Latin/CJK) installed via dnf — see packages/dnf.txt
#
# Icons:
#   - Tela-icon-theme — GTK/app icon theme, cloned from vinceliuice/Tela-icon-theme
#
# Cursors:
#   - HChisaBLZ (Hyprland native, hyprcursor format)
#   - XChisaBLZ (X11/XCursor format, for GTK/flatpak apps)
#   - Both from JustTuturu/TuturuCursor private repo (requires gh auth)
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
SCREENSHOT_DIR="${HOME}/Pictures/Screenshots"
# Actual theme names (must match index.theme / manifest.hl)
HYPR_CURSOR="HChisaBLZ"
X_CURSOR="XChisaBLZ"
# GitHub release archive names (same installed theme names)
HYPR_CURSOR_ARCHIVE="HChisaBLZ"
X_CURSOR_ARCHIVE="XChisaBLZ"

# ========================== GH CHECK ==========================================
check_gh() {
    if ! cmd_exists gh; then
        fail "gh (GitHub CLI) is required. Install with: sudo dnf install gh"
    fi

    if ! gh auth status &>/dev/null; then
        fail "gh is not authenticated. Run: gh auth login"
    fi
}

# ========================== FONTS =============================================
install_fonts() {
    mkdir -p "${FONT_DIR}"

    # Only NF Regular+Bold and NFM (Mono) Regular+Bold weights, with Italic variants
    local -a wanted=(
        JetBrainsMonoNerdFont-Regular.ttf
        JetBrainsMonoNerdFont-Bold.ttf
        JetBrainsMonoNerdFont-Italic.ttf
        JetBrainsMonoNerdFont-BoldItalic.ttf
        JetBrainsMonoNerdFontMono-Regular.ttf
        JetBrainsMonoNerdFontMono-Bold.ttf
        JetBrainsMonoNerdFontMono-Italic.ttf
        JetBrainsMonoNerdFontMono-BoldItalic.ttf
    )

    # Check if ALL wanted fonts are already present
    local missing=0
    for f in "${wanted[@]}"; do
        [[ -f "${FONT_DIR}/${f}" ]] || { missing=1; break; }
    done
    if [[ ${missing} -eq 0 ]]; then
        ok "JetBrains Mono Nerd Font already installed"
        return
    fi

    info "Downloading JetBrains Mono Nerd Font via gh"
    local archive="${TEMP_DIR}/JetBrainsMono.tar.xz"

    gh release download --repo ryanoasis/nerd-fonts \
        --pattern "JetBrainsMono.tar.xz" \
        --output "${archive}" \
        || fail "Failed to download JetBrains Mono Nerd Font"

    # Extract only wanted weights (archive contains flat .ttf files)
    tar -xf "${archive}" -C "${TEMP_DIR}" --wildcards \
        "${wanted[@]}" || fail "Failed to extract JetBrains Mono Nerd Font"

    local extracted=0
    for f in "${wanted[@]}"; do
        if [[ -f "${TEMP_DIR}/${f}" ]]; then
            mv -f "${TEMP_DIR}/${f}" "${FONT_DIR}/"
            ((extracted++)) || true
        else
            warn "Missing from archive: ${f}"
        fi
    done

    if [[ ${extracted} -eq 0 ]]; then
        fail "No font files extracted — archive may be corrupt or format changed"
    fi

    fc-cache -f 2>/dev/null

    ok "JetBrains Mono NF + NFM installed (${extracted} weights)"
}

# ========================== CURSORS ===========================================
install_cursors() {
    if [[ ! -t 0 ]]; then
        info "Non-interactive shell — skipping cursor install"
        return
    fi

    echo -ne "\n  Install private cursor theme? [y/N] "
    read -r reply || reply=""
    if [[ ! "${reply}" =~ ^[Yy]$ ]]; then
        info "Skipping cursor install"
        return
    fi

    local -a themes=() archives=()
    themes+=("${HYPR_CURSOR}")  archives+=("${HYPR_CURSOR_ARCHIVE}")
    themes+=("${X_CURSOR}")    archives+=("${X_CURSOR_ARCHIVE}")

    for i in "${!themes[@]}"; do
        local theme="${themes[i]}"
        local archive_name="${archives[i]}"
        local dest="${ICON_DIR}/${theme}"

        if [[ -d "${dest}" ]]; then
            ok "${theme} already installed"
            continue
        fi

        info "Downloading ${archive_name} → ${theme} from JustTuturu/TuturuCursor"
        local archive="${TEMP_DIR}/${archive_name}.tar.gz"

        if ! gh release download --repo "JustTuturu/TuturuCursor" \
            --pattern "${archive_name}.tar.gz" \
            --output "${archive}" 2>/dev/null; then
            warn "Failed to download ${archive_name}"
            continue
        fi

        mkdir -p "${ICON_DIR}"
        tar -xf "${archive}" -C "${ICON_DIR}" 2>/dev/null \
            || { warn "Failed to extract ${archive_name}"; continue; }

        # Verify extraction produced the expected theme directory
        if [[ -d "${dest}" ]]; then
            ok "${archive_name} → ${dest}"
        else
            warn "Extracted but expected dir not found: ${dest}"
        fi
    done
}

# ========================== ICONS =============================================
install_icons() {
    local repo="https://github.com/vinceliuice/Tela-icon-theme.git"
    local clone_dir="${TEMP_DIR}/tela-icons"

    if [[ -d "${ICON_DIR}/Tela-dark" ]]; then
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

    if [[ -d "${ICON_DIR}/Tela-dark" ]]; then
        ok "Tela icon theme → ${ICON_DIR}"
    else
        fail "Tela install failed — ${ICON_DIR}/Tela-dark not found"
    fi
}

# ========================== SET DEFAULTS ======================================
set_defaults() {
    info "Setting default cursor and icon theme"

    mkdir -p "${SCREENSHOT_DIR}"

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
        gsettings set org.gnome.desktop.interface icon-theme    "Tela-dark"      2>/dev/null || true
        ok "gsettings: ${X_CURSOR} + Tela-dark"
    fi

    export XCURSOR_THEME="${X_CURSOR}"
    export XCURSOR_SIZE="${CURSOR_SIZE}"

    if cmd_exists flatpak; then
        flatpak override --filesystem=~/.local/share/icons:ro --user 2>/dev/null || true
        ok "Flatpak: allow read access to ~/.local/share/icons"
    fi
}

# ========================== MAIN ==============================================
if [[ $# -gt 0 ]]; then
    echo "Usage: ./install-assets.sh"
    exit 1
fi

check_gh
install_fonts
install_icons
install_cursors
set_defaults

echo -e "\n${GREEN}${BOLD}=== Assets Installed ===${RESET}"
