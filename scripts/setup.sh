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

# ========================== MODULE: BASE DEPS ================================
run_deps() {
    info "Installing base dependencies"
    sudo dnf upgrade --refresh -y
    sudo dnf install -y \
        gcc gcc-c++ make cmake \
        python3-pip python3-devel nodejs npm \
        git stow xdg-user-dirs \
        pipewire pipewire-utils wireplumber \
        qt6-qtwayland qt5-qtwayland xdg-utils \
        bluez bluez-libs \
        nemo ripgrep bat fzf tmux eza zoxide fastfetch gh vlc gimp obs-studio

    # Lazy git
    sudo dnf copr enable -y dejan/lazygit
    sudo dnf install -y lazygit

    # Starship
    sudo dnf copr enable -y atim/starship
    sudo dnf install -y starship

    # Ghostty
    sudo dnf copr enable -y scottames/ghostty
    sudo dnf install -y ghostty

    # Fonts
    local font_script="$REPO_ROOT/scripts/install-fonts.sh"
    if [ -x "$font_script" ]; then
        if "$font_script" >/dev/null 2>&1; then
            ok "Fonts checked/installed"
        fi
    fi
}

# ========================== MODULE: FILES ====================================
run_files() {
    info "Stowing dotfiles..."

    if ! cmd_exists stow; then
        sudo dnf install -y stow || { fail "Could not install stow"; return 1; }
    fi

    local config_target="$HOME/.config"
    local home_target="$HOME"
    local dotconfig="$REPO_ROOT/.config"
    local count=0

    # ===== LIST PACKAGES HERE =====
    local config_packages=(
        "colors"
        "eza"
        "fontconfig"
        "ghostty"
        "hypr"
        "matugen"
        "rofi"
        "starship"
        "tmux"
        "uv"
        "waybar"
        "wlogout"
        "yazi"
        "zed"
    )
    # ===============================

    for pkg in "${config_packages[@]}"; do
        local package_target="$config_target/$pkg"
        if [ -L "$package_target" ]; then
            rm "$package_target"
            echo "  Removed old symlink: $pkg"
        fi

        if [ -d "$dotconfig/$pkg" ]; then
            mkdir -p "$package_target"

            if [ -n "${FORCE:-}" ]; then
                stow -t "$package_target" -d "$dotconfig" --restow "$pkg" 2>/dev/null \
                    && ok "$pkg" && ((count++)) \
                    || warn "$pkg failed"
            else
                stow -t "$package_target" -d "$dotconfig" "$pkg" 2>/dev/null \
                    && ok "$pkg" && ((count++)) \
                    || warn "$pkg failed"
            fi
        else
            warn "$pkg not found in dotfiles"
        fi
    done

    # Stow zsh to HOME (not .config)
    if [ -n "${FORCE:-}" ]; then
        stow -t "$home_target" -d "$REPO_ROOT" --restow zsh 2>/dev/null \
            && ok "zsh" && ((count++)) || warn "zsh failed"
    else
        stow -t "$home_target" -d "$REPO_ROOT" zsh 2>/dev/null \
            && ok "zsh" && ((count++)) || warn "zsh failed"
    fi

    # Noctalia Shell — link quickshell config to system noctalia
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

    # Enable COPR
    # Hyprland
    sudo dnf copr enable lionheartp/Hyprland -y || {
        fail "Failed to enable COPR"
        return 1
    }

    # Noctalia shell
    sudo dnf install --nogpgcheck \
        --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

    # Install packages (removed conflicting -git versions)
    sudo dnf install -y \
        awww \
        aquamarine \
        cliphist \
        glaze \
        gpu-screen-recorder \
        hyprcursor \
        hyprgraphics \
        hypridle \
        hyprland \
        hyprland-contrib \
        hyprland-guiutils \
        hyprland-plugins \
        hyprland-protocols \
        hyprland-qt-support \
        hyprlang \
        hyprlauncher \
        hyprpwcenter \
        hyprlock \
        hyprpaper \
        hyprpicker \
        hyprpolkitagent \
        hyprqt6engine \
        hyprshot \
        hyprwire \
        hyprtoolkit \
        hyprsunset \
        hyprutils \
        hyprwayland-scanner \
        hyprshutdown\
        python-imageio-ffmpeg \
        matugen \
        nwg-look \
        python-screeninfo \
        qt6ct \
        quickshell \
        uwsm \
        waypaper \
        xcur2png \
        xdg-desktop-portal-hyprland \
        grimblast \
        wlr-randr
    # Install Noctalia shell
    sudo dnf install -y noctalia-shell

    # Enable services
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
        # Full install: base deps + dotfiles + shell + hyprland
        sudo_init_keepalive
        trap sudo_stop_keepalive EXIT

        echo -e "${GREEN}${BOLD}=== Installing Dotfiles + Hyprland ===${RESET}\n"
        run_deps
        run_files
        run_shell
        run_hypr

        echo ""
        echo -e "${GREEN}${BOLD}=== Complete! ===${RESET}"
        echo -e "  Log out and select 'Hyprland (UWSM)' at login"
        ;;

    install-base)
        # Base install: deps + dotfiles + shell (no hyprland)
        sudo_init_keepalive
        trap sudo_stop_keepalive EXIT

        echo -e "${GREEN}${BOLD}=== Installing Dotfiles Only ===${RESET}\n"
        run_deps
        run_files
        run_shell

        echo ""
        echo -e "${GREEN}${BOLD}=== Complete! ===${RESET}"
        echo -e "  Restart your terminal or run: exec zsh"
        ;;

    install-hypr)
        # Hyprland only (for existing dotfiles)
        sudo_init_keepalive
        trap sudo_stop_keepalive EXIT

        echo -e "${GREEN}${BOLD}=== Installing Hyprland ===${RESET}\n"
        run_hypr

        echo ""
        echo -e "${GREEN}${BOLD}=== Complete! ===${RESET}"
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
