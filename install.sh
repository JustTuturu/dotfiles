#!/usr/bin/env bash
# install.sh — Dotfiles & Hyprland installer (Fedora)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="${REPO_ROOT}/packages"

# ========================== COLORS & UTILITIES ==============================
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'
MAGENTA='\e[35m'; CYAN='\e[36m'; WHITE='\e[37m'; BOLD='\e[1m'; RESET='\e[0m'

info()  { echo -e "\n  ${BLUE}[i]${RESET} ${BOLD}$*${RESET}"; }
ok()    { echo -e "  ${GREEN}[✓]${RESET} ${BOLD}$*${RESET}"; }
warn()  { echo -e "  ${YELLOW}[!]${RESET} ${BOLD}$*${RESET}"; }
fail()  { echo -e "  ${RED}[✗]${RESET} ${BOLD}$*${RESET}" && exit 1; }

cmd_exists() { command -v "$1" &>/dev/null; }

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

prevent_root() {
    if [[ "$(id -u)" == 0 ]]; then
        echo -e "\n  ${RED}[✗]${RESET} ${BOLD}Do not run this script as root.${RESET}"
        echo -e "  ${YELLOW}[!]${RESET} ${BOLD}The installer will prompt for sudo when needed.${RESET}\n"
        exit 1
    fi
}

sudo_stop_keepalive() {
    sudo -K
    kill %1 2>/dev/null || true
}

sudo_keepalive() {
    (while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done) &
}

sudo_init_keepalive() {
    info "Initializing sudo (enter password if prompted)"
    if sudo -v 2>/dev/null; then
        sudo_keepalive
    else
        warn "Sudo initialization failed. Some steps may require manual intervention."
    fi
}

# ========================== ASSET CONFIG ======================================
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

CURSOR_OWNER="JustTuturu"
CURSOR_REPO="TuturuCursor"
CURSOR_URL="https://github.com/${CURSOR_OWNER}/${CURSOR_REPO}/releases/latest/download"

HYPR_CURSOR="HChisaBLZ"
X_CURSOR="XChisaBLZ"
CURSOR_SIZE=24

ICON_DIR="${HOME}/.local/share/icons"
FONT_DIR="${HOME}/.local/share/fonts"

# ========================== MODULE: PACKAGES ==================================
run_packages() {
    info "Enabling COPR repositories"
    local -a copr_repos
    read_packages "${PKG_DIR}/copr.txt" copr_repos || true

    local -a copr_pkgs=()
    for entry in "${copr_repos[@]}"; do
        sudo dnf copr enable -y "$entry"
        # Trailing : means repo-only (no package to install)
        [[ "${entry}" == *: ]] && continue
        copr_pkgs+=("${entry##*/}")   # take part after last /
    done

    info "Installing packages"
    local -a pkgs
    read_packages "${PKG_DIR}/dnf.txt" pkgs || true
    sudo dnf upgrade --refresh -y
    sudo dnf install -y --setopt=install_weak_deps=False "${pkgs[@]}" "${copr_pkgs[@]}"
}

# ========================== MODULE: BRAVE =====================================
run_brave() {
    info "Installing Brave Browser (Nightly)"

    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager addrepo \
        --from-repofile=https://brave-browser-rpm-nightly.s3.brave.com/brave-browser-nightly.repo
    sudo dnf install -y brave-browser-nightly

    ok "Brave Nightly installed"
}

# ========================== MODULE: OPTIONAL ==================================
run_optional() {
    info "Optional packages available"

    local -a optional_deps
    read_packages "${PKG_DIR}/optional.txt" optional_deps || return 0

    local to_install=()

    for pkg in "${optional_deps[@]}"; do
        echo -ne "  Install ${BOLD}${pkg}${RESET}? [y/N] "
        read -r reply
        [[ "${reply}" =~ ^[Yy]$ ]] && to_install+=("${pkg}")
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        sudo dnf install --setopt=install_weak_deps=False "${to_install[@]}"
        ok "Optional packages installed"
    else
        info "No optional packages selected"
    fi
}

# ========================== MODULE: FONTS =====================================
install_fonts() {
    mkdir -p "${FONT_DIR}"

    if fc-list | grep -qi "JetBrainsMono.*Nerd Font"; then
        ok "JetBrains Mono Nerd Font already installed"
        return
    fi

    info "Downloading JetBrains Mono Nerd Font"
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
    ok "JetBrains Mono NF + NFM installed"
}

# ========================== MODULE: CURSORS ===================================
run_cursors() {
    # Ask for GH token once
    local token="${GH_TOKEN:-}"
    if [[ -z "${token}" ]]; then
        echo -e "\n  ${YELLOW}[!]${RESET} Cursor repo is private — GitHub token required" >&2
        echo -e "  ${BLUE}[i]${RESET} Create at: https://github.com/settings/tokens (scope: repo)" >&2
        read -rsp "  Enter GitHub Token: " token
        echo >&2
    fi
    [[ -z "${token}" ]] && { warn "No token — skipping cursor install"; return; }

    for name in "${HYPR_CURSOR}" "${X_CURSOR}"; do
        local dest="${ICON_DIR}/${name}"
        if [[ -d "${dest}" ]]; then
            ok "${name} already installed"
            continue
        fi

        info "Downloading ${name}"
        local archive="${TEMP_DIR}/${name}.tar.gz"
        curl -fsSL \
            -H "Authorization: Bearer ${token}" \
            -L "${CURSOR_URL}/${name}.tar.gz" -o "${archive}"

        mkdir -p "${ICON_DIR}"
        tar -xf "${archive}" -C "${ICON_DIR}"
        ok "${name} → ${dest}"
    done
}

# ========================== MODULE: ICONS =====================================
install_icons() {
    local repo="https://github.com/vinceliuice/Tela-icon-theme.git"
    local clone_dir="${TEMP_DIR}/tela-icons"

    if [[ -d "${ICON_DIR}/Tela-dark" ]]; then
        ok "Tela icon theme already installed"
        return
    fi

    info "Installing Tela icon theme"

    if ! cmd_exists git; then
        fail "git is not installed — required to clone Tela icons"
    fi

    git clone --depth 1 "${repo}" "${clone_dir}" &>/dev/null \
        || fail "Cannot clone Tela icon theme"

    cd "${clone_dir}"

    ./install.sh 2>/dev/null \
        || fail "Tela icon theme install failed"

    if [[ -d "${ICON_DIR}/Tela-dark" ]]; then
        ok "Tela icon theme → ${ICON_DIR}"
    else
        fail "Tela install failed — ${ICON_DIR}/Tela-dark not found"
    fi
}

# ========================== MODULE: SET DEFAULTS ==============================
set_defaults() {
    info "Setting default cursor and icon theme"

    if cmd_exists hyprctl; then
        hyprctl setcursor "${HYPR_CURSOR}" "${CURSOR_SIZE}" 2>/dev/null || true
        ok "hyprctl: ${HYPR_CURSOR} (size ${CURSOR_SIZE})"
    fi

    if cmd_exists gsettings; then
        gsettings set org.gnome.desktop.interface cursor-theme "${X_CURSOR}" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size "${CURSOR_SIZE}" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "Tela-dark" 2>/dev/null || true
        ok "gsettings: ${X_CURSOR} + Tela-dark"
    fi

    local zshenv="${HOME}/.zshenv"
    if [[ -f "${zshenv}" ]] && grep -q "XCURSOR_THEME" "${zshenv}"; then
        sed -i \
            -e "s|export XCURSOR_THEME=.*|export XCURSOR_THEME=${X_CURSOR}|" \
            -e "s|export XCURSOR_SIZE=.*|export XCURSOR_SIZE=${CURSOR_SIZE}|" \
            "${zshenv}"
        ok "Updated XCURSOR_* in ~/.zshenv"
    else
        printf "\nexport XCURSOR_THEME=%s\nexport XCURSOR_SIZE=%s\n" \
            "${X_CURSOR}" "${CURSOR_SIZE}" >> "${zshenv}"
        ok "Added XCURSOR_* to ~/.zshenv"
    fi

    if cmd_exists flatpak; then
        flatpak override --filesystem=~/.local/share/icons:ro --user 2>/dev/null || true
        ok "Flatpak: allow read access to ~/.local/share/icons"
    fi
}

# ========================== MODULE: ASSETS ====================================
run_assets() {
    install_fonts
    install_icons
    run_cursors
    set_defaults
}

# ========================== MODULE: FILES =====================================
run_files() {
    info "Stowing dotfiles..."

    if ! cmd_exists stow; then
        sudo dnf install -y stow || { fail "Could not install stow"; return 1; }
    fi

    local -a stow_packages
    read_packages "${PKG_DIR}/stow.txt" stow_packages || return 0

    local count=0
    local failed=0

    for pkg in "${stow_packages[@]}"; do
        if [ ! -d "$REPO_ROOT/$pkg" ]; then
            warn "$pkg not found in dotfiles"
            ((failed++))
            continue
        fi

        if stow -t "$HOME" -d "$REPO_ROOT" --no-folding -S "$pkg" 2>/dev/null; then
            ok "$pkg"
            ((count++))
            continue
        fi

        if stow -t "$HOME" -d "$REPO_ROOT" --no-folding --adopt -S "$pkg" 2>/dev/null; then
            ok "$pkg (adopted existing files)"
            ((count++))
            continue
        fi

        if [ -n "${FORCE:-}" ]; then
            if stow -t "$HOME" -d "$REPO_ROOT" --no-folding -R "$pkg" 2>/dev/null; then
                ok "$pkg (force restowed)"
                ((count++))
                continue
            fi
        fi

        fail "$pkg — could not stow. Try: stow -t $HOME -d $REPO_ROOT --adopt -S $pkg"
        ((failed++))
    done

    # Noctalia Shell
    if cmd_exists noctalia-shell || [ -d /etc/xdg/quickshell/noctalia-shell ]; then
        mkdir -p ~/.config/quickshell
        if [ -L ~/.config/quickshell ] && [ ! -d ~/.config/quickshell ]; then
            rm ~/.config/quickshell
        fi
        if [ ! -L ~/.config/quickshell ] && [ -d /etc/xdg/quickshell/noctalia-shell ]; then
            ln -sf /etc/xdg/quickshell/noctalia-shell ~/.config/quickshell
            ok "Noctalia Shell linked"
        fi
    fi

    info "Stowed $count packages"
    [ "$failed" -gt 0 ] && warn "$failed packages failed to stow"

    # Generate initial matugen colors
    if cmd_exists matugen && [ -f "$HOME/Pictures/Wallpapers/wallpaper.jpg" ]; then
        info "Generating initial matugen colors..."
        matugen image "$HOME/Pictures/Wallpapers/wallpaper.jpg" --prefer darkness && ok "matugen colors generated" \
            || warn "matugen failed — run manually: matugen image ~/Pictures/Wallpapers/wallpaper.jpg --prefer darkness"
    else
        warn "matugen: run manually after setting wallpaper"
    fi
}

# ========================== MODULE: SHELL =====================================
run_shell() {
    info "Setting up Zsh..."

    if ! cmd_exists zsh; then
        sudo dnf install -y zsh || { fail "Could not install zsh"; return 1; }
    fi

    if ! grep -q "$(which zsh)" /etc/shells 2>/dev/null; then
        echo "$(which zsh)" | sudo tee -a /etc/shells >/dev/null
    fi

    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)"
        ok "Zsh set as default shell"
    fi

    ok "Zinit will auto-install on first zsh launch"
}

# ========================== MODULE: HYPRLAND ==================================
run_hypr() {
    info "Installing Hyprland ecosystem..."

    sudo dnf install -y --nogpgcheck \
        --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

    local -a hypr_deps
    read_packages "${PKG_DIR}/hypr.txt" hypr_deps || return 0
    [ ${#hypr_deps[@]} -gt 0 ] && sudo dnf install -y "${hypr_deps[@]}"

    systemctl --user enable --now pipewire.service wireplumber.service 2>/dev/null || true

    echo ""
    echo -e "  ${CYAN}Add to ~/.config/hypr/hyprland.conf:${RESET}"
    echo -e "  ${YELLOW}exec-once = systemctl --user start hyprpolkitagent${RESET}"
    echo ""
}

# ========================== MAIN ==============================================
showhelp() {
    cat << 'EOF'

  Dotfiles Setup — Tuturu (Fedora)

  Usage: ./install.sh <command>

  Commands:
    install         Install dotfiles + Hyprland (full setup)
    install-base    Install dotfiles only (no Hyprland)
    install-hypr    Install Hyprland only (assumes dotfiles exist)
    install-assets  Install fonts, cursors, and icon themes only

  Options:
    FORCE=1         Overwrite existing configs during stow
    GH_TOKEN=...    GitHub token for private cursor repo

EOF
}

clear
prevent_root

case "${1:-help}" in
    install)
        sudo_init_keepalive
        trap sudo_stop_keepalive EXIT
        echo -e "${GREEN}${BOLD}=== Installing Dotfiles + Hyprland ===${RESET}\n"
        run_packages && run_brave && run_optional && run_assets && run_files && run_shell && run_hypr
        echo -e "\n${GREEN}${BOLD}=== Complete! ===${RESET}"
        echo -e "  Log out and select 'Hyprland (UWSM)' at login"
        ;;
    install-base)
        sudo_init_keepalive
        trap sudo_stop_keepalive EXIT
        echo -e "${GREEN}${BOLD}=== Installing Dotfiles Only ===${RESET}\n"
        run_packages && run_brave && run_optional && run_assets && run_files && run_shell
        echo -e "\n${GREEN}${BOLD}=== Complete! ===${RESET}"
        echo -e "  Restart your terminal or run: exec zsh"
        ;;
    install-hypr)
        sudo_init_keepalive
        trap sudo_stop_keepalive EXIT
        echo -e "${GREEN}${BOLD}=== Installing Hyprland ===${RESET}\n"
        run_packages && run_hypr
        echo -e "\n${GREEN}${BOLD}=== Complete! ===${RESET}"
        ;;
    install-assets)
        echo -e "${GREEN}${BOLD}=== Installing Assets (Fonts, Cursors, Icons) ===${RESET}\n"
        run_assets
        echo -e "\n${GREEN}${BOLD}=== Complete! ===${RESET}"
        echo -e "  Log out and log back in to apply cursor and icon theme."
        ;;
    help|--help|-h|"")
        showhelp
        ;;
    *)
        echo -e "${RED}Unknown command: $1${RESET}"
        showhelp
        exit 1
        ;;
esac