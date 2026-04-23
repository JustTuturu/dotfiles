#!/usr/bin/env bash
# setup.sh — Simplified dotfiles & Hyprland installer
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ========================== COLORS & UTILITIES ===============================
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'
MAGENTA='\e[35m'; CYAN='\e[36m'; WHITE='\e[37m'; BOLD='\e[1m'; RESET='\e[0m'

info()  { echo -e "\n  ${BLUE}[i]${RESET} ${BOLD}$*${RESET}"; }
ok()    { echo -e "  ${GREEN}[✓]${RESET} ${BOLD}$*${RESET}"; }
warn()  { echo -e "  ${YELLOW}[!]${RESET} ${BOLD}$*${RESET}"; }
fail()  { echo -e "  ${RED}[✗]${RESET} ${BOLD}$*${RESET}"; }

cmd_exists() { command -v "$1" &>/dev/null; }

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

# ========================== PACKAGE LISTS ====================================
COPR_REPOS=(
    atim/starship
    dejan/lazygit
    lihaohong/yazi
    lionheartp/Hyprland
    scottames/ghostty
    che/zed
)

BASE_DEPS=(
    gcc gcc-c++ make cmake
    python3-pip python3-devel nodejs npm
    git stow xdg-user-dirs
    pipewire pipewire-utils wireplumber
    qt6-qtwayland qt5-qtwayland xdg-utils
    bluez bluez-libs
    ripgrep bat fzf tmux eza zoxide
    fastfetch gh
)

OPTIONAL_DEPS=(
    nodejs npm
    vlc
    obs-studio
    blender
    btop
)

COPR_DEPS=(
    starship
    lazygit
    ghostty
    yazi
    zed
)

HYPR_DEPS=(
    hyprland
    uwsm
    hypridle
    hyprlock
    hyprpaper
    hyprpicker
    hyprshot
    hyprcursor
    hyprpolkitagent
    xdg-desktop-portal-hyprland
    hyprland-qt-support
    cliphist
    wlr-randr
    nwg-look
    qt6ct
    quickshell
    matugen
    noctalia-shell
    gpu-screen-recorder
)

STOW_PACKAGES=(
    eza
    fastfetch
    fontconfig
    ghostty
    gtk
    hypr
    matugen
    noctalia
    starship
    tmux
    uv
    yazi
    zed
    zsh
)

# ========================== MODULE: COPR REPOS ================================
run_copr() {
    info "Enabling COPR repositories"
    for repo in "${COPR_REPOS[@]}"; do
        sudo dnf copr enable -y "$repo"
    done
}

# ========================== MODULE: BASE DEPS ================================
run_deps() {
    info "Installing base dependencies"
    sudo dnf upgrade --refresh -y
    sudo dnf install -y --setopt=install_weak_deps=False "${BASE_DEPS[@]}"
    sudo dnf install -y --setopt=install_weak_deps=False "${COPR_DEPS[@]}"

    local assets_script="$REPO_ROOT/scripts/install-assets.sh"
    if [ -x "$assets_script" ]; then
        "$assets_script"
    fi
}

# ========================== MODULE: BRAVE ====================================
run_brave() {
    info "Installing Brave Browser (Nightly)"

    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager addrepo \
        --from-repofile=https://brave-browser-rpm-nightly.s3.brave.com/brave-browser-nightly.repo
    sudo dnf install -y brave-browser-nightly

    ok "Brave Nightly installed"
}

# ========================== MODULE: OPTIONAL =================================
run_optional() {
    info "Optional packages available"

    local to_install=()

    for pkg in "${OPTIONAL_DEPS[@]}"; do
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

# ========================== MODULE: FILES ====================================
run_files() {
    info "Stowing dotfiles..."

    if ! cmd_exists stow; then
        sudo dnf install -y stow || { fail "Could not install stow"; return 1; }
    fi

    local count=0
    local stow_opts=(-t "$HOME" -d "$REPO_ROOT")
    [ -n "${FORCE:-}" ] && stow_opts+=(--restow) || stow_opts+=(--stow)

    for pkg in "${STOW_PACKAGES[@]}"; do
        if [ -d "$REPO_ROOT/$pkg" ]; then
            # Remove conflicting real files/dirs that block stow
            case "$pkg" in
                zsh)
                    [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ] && rm "$HOME/.zshrc"
                    ;;
                tmux)
                    [ -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ] && rm "$HOME/.tmux.conf"
                    ;;
                *)
                    # Remove regular files that conflict with stow symlinks
                    if [ -d "$REPO_ROOT/$pkg/.config" ]; then
                        while IFS= read -r f; do
                            target="$HOME/$f"
                            if [ -e "$target" ] && [ ! -L "$target" ]; then
                                rm -f "$target"
                            fi
                        done < <(cd "$REPO_ROOT/$pkg" && find . -type f -not -path './.git/*')
                    fi
                    # Also handle top-level files (like .zshrc, .tmux.conf)
                    while IFS= read -r f; do
                        target="$HOME/$f"
                        if [ -e "$target" ] && [ ! -L "$target" ]; then
                            rm -f "$target"
                        fi
                    done < <(cd "$REPO_ROOT/$pkg" && find . -maxdepth 1 -type f)
                    ;;
            esac

            stow "${stow_opts[@]}" "$pkg" 2>/dev/null \
                && ok "$pkg" && ((count++)) \
                || warn "$pkg — stow conflict, try: stow -R -d $REPO_ROOT -t $HOME $pkg"
        else
            warn "$pkg not found in dotfiles"
        fi
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

    # Generate initial matugen colors
    if cmd_exists matugen && [ -f "$HOME/Pictures/Wallpapers/wallpaper.jpg" ]; then
        info "Generating initial matugen colors..."
        matugen image "$HOME/Pictures/Wallpapers/wallpaper.jpg" --prefer darkness && ok "matugen colors generated" \
            || warn "matugen failed — run manually: matugen image ~/Pictures/Wallpapers/wallpaper.jpg --prefer darkness"
    else
        warn "matugen: run manually after setting wallpaper"
    fi
}

# ========================== MODULE: SHELL ====================================
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

    sudo dnf install -y "${HYPR_DEPS[@]}"

    systemctl --user enable --now pipewire.service wireplumber.service 2>/dev/null || true

    echo ""
    echo -e "  ${CYAN}Add to ~/.config/hypr/hyprland.conf:${RESET}"
    echo -e "  ${YELLOW}exec-once = systemctl --user start hyprpolkitagent${RESET}"
    echo ""
}

# ========================== MAIN =============================================
showhelp() {
    cat << 'EOF'

  Dotfiles Setup — Tuturu (Fedora)

  Usage: ./setup.sh <command>

  Commands:
    install         Install dotfiles + Hyprland (full setup)
    install-base    Install dotfiles only (no Hyprland)
    install-hypr    Install Hyprland only (assumes dotfiles exist)

  Options:
    FORCE=1         Overwrite existing configs

EOF
}

clear
prevent_root

case "${1:-help}" in
    install)
        sudo_init_keepalive
        trap sudo_stop_keepalive EXIT
        echo -e "${GREEN}${BOLD}=== Installing Dotfiles + Hyprland ===${RESET}\n"
        run_copr && run_deps && run_brave && run_optional && run_files && run_shell && run_hypr
        echo -e "\n${GREEN}${BOLD}=== Complete! ===${RESET}"
        echo -e "  Log out and select 'Hyprland (UWSM)' at login"
        ;;
    install-base)
        sudo_init_keepalive
        trap sudo_stop_keepalive EXIT
        echo -e "${GREEN}${BOLD}=== Installing Dotfiles Only ===${RESET}\n"
        run_copr && run_deps && run_brave && run_optional && run_files && run_shell
        echo -e "\n${GREEN}${BOLD}=== Complete! ===${RESET}"
        echo -e "  Restart your terminal or run: exec zsh"
        ;;
    install-hypr)
        sudo_init_keepalive
        trap sudo_stop_keepalive EXIT
        echo -e "${GREEN}${BOLD}=== Installing Hyprland ===${RESET}\n"
        run_copr && run_hypr
        echo -e "\n${GREEN}${BOLD}=== Complete! ===${RESET}"
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