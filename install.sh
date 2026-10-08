#!/usr/bin/env bash
# install.sh — Tuturu's dotfiles installer (Fedora + Hyprland)
#
# Run straight on a fresh machine
#   curl -fsSL https://raw.githubusercontent.com/JustTuturu/dotfiles/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- stow

set -euo pipefail

# ========================== COLORS & UTILITIES ==============================
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'
BOLD='\e[1m'; RESET='\e[0m'

info()  { echo -e "\n  ${BLUE}[i]${RESET} ${BOLD}$*${RESET}"; }
ok()    { echo -e "  ${GREEN}[✓]${RESET} ${BOLD}$*${RESET}"; }
warn()  { echo -e "  ${YELLOW}[!]${RESET} ${BOLD}$*${RESET}"; }
fail()  { echo -e "  ${RED}[✗]${RESET} ${BOLD}$*${RESET}" && exit 1; }

cmd_exists() { command -v "$1" &>/dev/null; }

all_present() {
    local dir="$1"; shift
    local f
    for f in "$@"; do [[ -f "${dir}/${f}" ]] || return 1; done
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# ========================== SELF-BOOTSTRAP ===================================
# When piped via curl there is no local repo — clone it and re-exec.
if [[ ! -f "${REPO_ROOT}/packages/stow.txt" ]]; then
    info "No local dotfiles found — bootstrapping..."
    if ! cmd_exists git; then
        info "Installing git"
        # Explicit setopt: global dnf default is only written later in run_dnf_defaults().
        sudo dnf install -yq --setopt=install_weak_deps=False git || fail "Could not install git"
    fi
    if [[ ! -d "${HOME}/dotfiles" ]]; then
        git clone --depth=1 https://github.com/JustTuturu/dotfiles.git "${HOME}/dotfiles" \
            || fail "Could not clone dotfiles"
    fi
    exec "${HOME}/dotfiles/install.sh" "$@"
fi

PKG_DIR="${REPO_ROOT}/packages"

# Read package list from txt file into array (skip blanks & comments)
read_packages() {
    local file="$1"
    local -n arr="$2"
    arr=()
    if [[ ! -f "${file}" ]]; then
        warn "Package list not found: ${file}"
        return 1
    fi
    while IFS= read -r line; do
        [[ "${line}" =~ ^\s*$ || "${line}" =~ ^\s*# ]] && continue
        for pkg in ${line}; do
            arr+=("${pkg}")
        done
    done < "${file}"
}

# Fetch an asset from a public URL
download() {
    local url="$1" out="$2"

    cmd_exists curl || fail "curl is required to download assets"

    curl -fsSL --retry 3 -o "$out" "$url"
}

prevent_root() {
    if [[ "$(id -u)" == 0 ]]; then
        echo -e "\n  ${RED}[✗]${RESET} ${BOLD}Do not run this script as root.${RESET}"
        echo -e "  ${YELLOW}[!]${RESET} ${BOLD}The installer will prompt for sudo when needed.${RESET}\n"
        exit 1
    fi
}

SUDO_KEEPALIVE_PID=""

sudo_stop_keepalive() {
    sudo -K 2>/dev/null || true
    if [[ -n "${SUDO_KEEPALIVE_PID}" ]] && kill -0 "${SUDO_KEEPALIVE_PID}" 2>/dev/null; then
        kill "${SUDO_KEEPALIVE_PID}" 2>/dev/null || true
    fi
}

sudo_keepalive() {
    (while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done) &
    SUDO_KEEPALIVE_PID=$!
}

sudo_init_keepalive() {
    info "Initializing sudo (enter password if prompted)"
    if sudo -v 2>/dev/null; then
        sudo_keepalive
    else
        warn "Sudo initialization failed. Some steps may require manual intervention."
    fi
}

# Weak dependencies are disabled globally in /etc/dnf/dnf.conf by
# run_dnf_defaults(), so individual commands stay clean.
DNF_ARGS=(-yq)

dnf_install() {
    sudo dnf install "${DNF_ARGS[@]}" "$@"
}

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"; sudo_stop_keepalive' EXIT

ICON_DIR="${HOME}/.local/share/icons"
FONT_DIR="${HOME}/.local/share/fonts"

CURSOR_SIZE=24
# Theme names must match index.theme / manifest.hl; release archives use the same names.
HYPR_CURSOR="hyprcursor-ChisaBLZ"
X_CURSOR="xcursor-ChisaBLZ"

# ========================== MODULE: DNF DEFAULTS ==============================
# Persist install_weak_deps=False once in /etc/dnf/dnf.conf so every dnf invocation (now and in the future) skips weak dependencies
run_dnf_defaults() {
    if grep -qE '^\s*install_weak_deps\s*=\s*False' /etc/dnf/dnf.conf 2>/dev/null; then
        ok "Weak dependencies already disabled globally"
        return
    fi
    info "Disabling weak dependencies globally (/etc/dnf/dnf.conf)"
    echo "install_weak_deps=False" | sudo tee -a /etc/dnf/dnf.conf >/dev/null \
        || fail "Could not write /etc/dnf/dnf.conf"
    ok "Weak dependencies disabled"
}

# ========================== MODULE: RPM FUSION ================================
run_rpmfusion() {
    if rpm -q rpmfusion-free-release &>/dev/null && rpm -q rpmfusion-nonfree-release &>/dev/null; then
        ok "RPM Fusion already enabled"
        return
    fi
    info "Enabling RPM Fusion"
    sudo dnf install -yq --setopt=debuglevel=0 \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
}

# ========================== MODULE: PACKAGES ==================================
run_packages() {
    local -a copr_repos
    read_packages "${PKG_DIR}/copr.txt" copr_repos || fail "Missing packages/copr.txt"

    local -a copr_pkgs=()
    for entry in "${copr_repos[@]}"; do
        sudo dnf copr enable -yq "$entry" &>/dev/null || true
        [[ "${entry}" == *: ]] && continue
        copr_pkgs+=("${entry##*/}")
    done

    local -a pkgs
    read_packages "${PKG_DIR}/dnf.txt" pkgs || fail "Missing packages/dnf.txt"
    info "Installing system packages"
    sudo dnf install -yq --setopt=debuglevel=0 \
        "${pkgs[@]}" "${copr_pkgs[@]}"
}

# ========================== MODULE: APP-STREAM METADATA =======================
run_appstream() {
    info "Upgrading app-stream metadata"
    sudo dnf group upgrade core -yq || true
    ok "App-stream metadata upgraded"
}

# ========================== MODULE: OPTIMIZATIONS =============================
run_optimizations() {
    info "Applying system optimizations"

    # Dual-boot: set RTC to UTC (fixes time drift with Windows)
    if [[ "$(timedatectl show --property=LocalRTC --value)" != "no" ]]; then
        sudo timedatectl set-local-rtc 0
        ok "RTC set to UTC (dual-boot friendly)"
    fi

    # Disable NetworkManager-wait-online to speed up boot
    if systemctl is-enabled NetworkManager-wait-online.service &>/dev/null; then
        sudo systemctl disable NetworkManager-wait-online.service
        ok "Disabled NetworkManager-wait-online.service"
    fi
}

# ========================== MODULE: SHELL =====================================
run_shell() {
    info "Setting up Zsh..."

    if ! cmd_exists zsh; then
        info "Installing Zsh"
        sudo dnf install -yq --setopt=debuglevel=0 zsh
    fi

    if ! grep -q "$(which zsh)" /etc/shells 2>/dev/null; then
        echo "$(which zsh)" | sudo tee -a /etc/shells >/dev/null
    fi

    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)"
        ok "Zsh set as default shell"
    fi

    if ! cmd_exists starship; then
        info "Installing Starship"
        curl -sS https://starship.rs/install.sh | sh -s -- -y || fail "Starship installation failed"
        ok "Starship installed"
    else
        ok "Starship already installed"
    fi

    ok "Zinit will auto-install on first zsh launch"
}

# ========================== MODULE: HYPRLAND ==================================
run_hypr() {
    local -a hypr_deps
    read_packages "${PKG_DIR}/hypr.txt" hypr_deps || fail "Missing packages/hypr.txt"
    if [ ${#hypr_deps[@]} -gt 0 ]; then
        info "Installing Hyprland ecosystem"
        sudo dnf install -yq --setopt=debuglevel=0 "${hypr_deps[@]}"
    fi

    systemctl --user enable --now pipewire.service wireplumber.service &>/dev/null || true

    ok "Hyprland ecosystem ready"
}

# ========================== MODULE: FILES (STOW) ==============================
run_files() {
    info "Stowing dotfiles..."

    if ! cmd_exists stow; then
        dnf_install stow || { fail "Could not install stow"; return 1; }
    fi

    local -a stow_packages
    read_packages "${PKG_DIR}/stow.txt" stow_packages || fail "Missing packages/stow.txt"

    local count=0
    local failed=0

    for pkg in "${stow_packages[@]}"; do
        if [ ! -d "$REPO_ROOT/$pkg" ]; then
            warn "$pkg not found in dotfiles"
            failed=$((failed + 1))
            continue
        fi

        while IFS= read -r -d '' source; do
            local relative target
            relative="${source#"$REPO_ROOT/$pkg/"}"
            target="$HOME/$relative"
            if [[ -L "$target" ]] && [[ "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
                unlink "$target"
            fi
        done < <(find "$REPO_ROOT/$pkg" -type f -print0)

        if stow -t "$HOME" -d "$REPO_ROOT" --no-folding -S "$pkg" 2>/dev/null; then
            ok "$pkg"
            count=$((count + 1))
            continue
        fi

        warn "$pkg — could not stow"
        failed=$((failed + 1))
    done

    info "Stowed $count packages"
    [ "$failed" -gt 0 ] && warn "$failed packages failed to stow"

    if cmd_exists matugen && [ -f "$REPO_ROOT/wallpapers/Chisa.jpg" ]; then
        info "Generating initial matugen colors..."
        matugen image "$REPO_ROOT/wallpapers/Chisa.jpg" --prefer darkness && ok "matugen colors generated" \
            || warn "matugen failed — run manually"
    else
        warn "matugen: run manually after setting wallpaper"
    fi
}

# ========================== MODULE: FONTS =====================================
# Official JetBrains Mono (with ligatures) for the Zed IDE
install_fonts() {
    local -a wanted=(
        JetBrainsMono-Regular.ttf
        JetBrainsMono-SemiBold.ttf
    )

    if all_present "${FONT_DIR}" "${wanted[@]}"; then
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

    # Official zip nests TTFs under fonts/ttf/
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

# ========================== MODULE: EXTRA FONTS ===============================
# Downloaded directly from upstream (Google Fonts / GitHub)
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

    local -a names=()
    local entry
    for entry in "${files[@]}"; do
        names+=("${entry%%|*}")
    done
    if all_present "${FONT_DIR}" "${names[@]}"; then
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

# ========================== MODULE: CURSORS ===================================
# Always installs when missing. The live hyprctl/gsettings calls only apply inside a session; the persistent theme comes from hypr/conf/environment.lua and applies on next login regardless.
install_cursor_theme() {
    local theme="$1"
    local archive="${TEMP_DIR}/${theme}.tar.gz"
    local source="${TEMP_DIR}/${theme}"
    local user_dest="${ICON_DIR}/${theme}"
    local system_dest="/usr/share/icons/${theme}"

    if [[ -d "${ICON_DIR}/${theme}" ]]; then
        ok "${theme} already installed"
        return
    fi

    info "Downloading ${theme} from JustTuturu/Chisa-Hyprcursor"
    if ! download \
        "https://github.com/JustTuturu/Chisa-Hyprcursor/releases/latest/download/${theme}.tar.gz" \
        "${archive}"; then
        warn "Failed to download ${theme}"
        return
    fi

    if ! tar -xf "${archive}" -C "${TEMP_DIR}" 2>/dev/null; then
        warn "Failed to extract ${theme}"
        return
    fi

    if [[ ! -d "${source}" ]]; then
        warn "Extracted but expected directory not found: ${source}"
        return
    fi

    if cp -a "${source}" "${ICON_DIR}/"; then
        ok "${theme} copied to ${user_dest}"
    else
        warn "Failed to copy ${theme} to ${ICON_DIR}"
        return
    fi

    if sudo cp -a "${source}" /usr/share/icons/ \
        && sudo chown -R root:root "${system_dest}" \
        && sudo chmod -R a+rX "${system_dest}"; then
        ok "${theme} copied to ${system_dest} (root:root, a+rX)"
    else
        warn "Failed to install ${theme} system-wide"
    fi
}

install_cursors() {
    if [[ -d "${ICON_DIR}/${X_CURSOR}" && -d "${ICON_DIR}/${HYPR_CURSOR}" ]]; then
        ok "Cursor themes already installed"
        return
    fi

    mkdir -p "${ICON_DIR}"
    install_cursor_theme "${X_CURSOR}"
    install_cursor_theme "${HYPR_CURSOR}"
}

# ========================== MODULE: ICONS =====================================
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

    info "Installing Tela icon theme"
    git clone --depth 1 "$repo" "$clone_dir" \
        && "$clone_dir/install.sh"

    if [[ -f "${ICON_DIR}/Tela-dark/index.theme" ]]; then
        ok "Tela icon theme → ${ICON_DIR}"
    else
        fail "Tela install failed — ${ICON_DIR}/Tela-dark not found"
    fi
}

# ========================== MODULE: DESKTOP DEFAULTS ==========================
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

set_defaults() {
    info "Setting default cursor and icon theme"

    set_cursor_defaults
    set_icon_default

    if cmd_exists flatpak; then
        flatpak override --filesystem=~/.local/share/icons:ro --user 2>/dev/null || true
        ok "Flatpak: allow read access to ~/.local/share/icons"
    fi
}

# ========================== MODULE: APPS ======================================
install_brave() {
    info "Installing Brave Browser"
    dnf_install dnf-plugins-core
    sudo dnf config-manager addrepo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    dnf_install brave-origin
    ok "Brave installed"
}

install_zed() {
    if cmd_exists zed; then ok "Zed already installed"; return; fi
    info "Installing Zed"
    curl -f https://zed.dev/install.sh | sh || fail "Zed installation failed"
    ok "Zed installed"
}

install_herdr() {
    info "Installing Herdr"
    curl -fsSL https://herdr.dev/install.sh | sh || fail "Herdr installation failed"
    ok "Herdr installed"
}

install_bun() {
    info "Installing Bun"
    curl -fsSL https://bun.com/install | bash || fail "Bun installation failed"
    ok "Bun installed"
}

install_uv() {
    if cmd_exists uv; then ok "UV already installed"; return; fi
    info "Installing UV"
    curl -LsSf https://astral.sh/uv/install.sh | sh || fail "UV installation failed"
    ok "UV installed"
}

install_lazygit() {
    info "Installing Lazygit from source"
    dnf_install golang || fail "Go installation failed"
    mkdir -p "$HOME/.local/bin" || fail "Could not create ~/.local/bin"
    GOBIN="$HOME/.local/bin" go install github.com/jesseduffield/lazygit@latest \
        || fail "Lazygit source installation failed"
    ok "Lazygit installed to ~/.local/bin"
}

install_obs() {
    info "Installing OBS Studio"
    dnf_install obs-studio || fail "OBS Studio installation failed"
    ok "OBS Studio installed"
}

install_blender() {
    info "Installing Blender"
    dnf_install blender || fail "Blender installation failed"
    ok "Blender installed"
}

install_btop() {
    info "Installing btop"
    dnf_install btop || fail "btop installation failed"
    ok "btop installed"
}

install_apps() {
    install_obs
    install_blender
    install_btop
    install_brave
    install_zed
    install_bun
    install_uv
    install_herdr
    install_lazygit
}

# ========================== PHASES ============================================
# Sequential calls: set -e already aborts on the first failure, so no && chains.
run_system() {
    run_dnf_defaults
    run_rpmfusion
    run_packages
    run_appstream
    run_optimizations
    run_shell
    run_hypr
    run_files
}

run_assets() {
    install_fonts
    install_extra_fonts
    install_icons
    install_cursors
    set_defaults
}

# ========================== MAIN ==============================================
showhelp() {
    cat << 'EOF'

  Dotfiles Setup — Tuturu (Fedora)

  Usage: ./install.sh [command]

  Commands:
    full    Full setup: system + assets + apps (default)
    stow    Stow dotfiles only (re-run after pulling updates)

  Fresh machine (no clone needed):
    curl -fsSL https://raw.githubusercontent.com/JustTuturu/dotfiles/main/install.sh | bash

EOF
}

clear
prevent_root

case "${1:-full}" in
    full)
        sudo_init_keepalive
        echo -e "${GREEN}${BOLD}=== Full System Setup ===${RESET}\n"
        run_system
        run_assets
        install_apps
        echo -e "\n${GREEN}${BOLD}=== Complete! ===${RESET}"
        echo -e "  Log out and select 'Hyprland' at login"
        ;;
    stow)
        run_files
        ok "Dotfiles stowed"
        ;;
    help|--help|-h)
        showhelp
        ;;
    *)
        echo -e "${RED}Unknown command: $1${RESET}"
        showhelp
        exit 1
        ;;
esac
