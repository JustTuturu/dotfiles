#!/usr/bin/env bash
# Installs the Fedora packages and Hyprland components required by these dotfiles.
# Usage: ./install-system.sh {full|stow|help}
# install-system.sh — Dotfiles & Hyprland installer (Fedora)

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

SUDO_KEEPALIVE_PID=""

sudo_stop_keepalive() {
    sudo -K
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
    progress_spinner "Installing system packages" \
        sudo dnf install -yq --setopt=install_weak_deps=False --setopt=debuglevel=0 \
            "${pkgs[@]}" "${copr_pkgs[@]}"
}

# ========================== MODULE: RPM FUSION ================================
run_rpmfusion() {
    if rpm -q rpmfusion-free-release &>/dev/null && rpm -q rpmfusion-nonfree-release &>/dev/null; then
        ok "RPM Fusion already enabled"
        return
    fi
    progress_spinner "Enabling RPM Fusion" \
        sudo dnf install -yq --setopt=debuglevel=0 \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
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
        progress_spinner "Installing Zsh" sudo dnf install -yq --setopt=debuglevel=0 zsh
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
        curl -sS https://starship.rs/install.sh | sh || fail "Starship installation failed"
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
        progress_spinner "Installing Hyprland ecosystem" \
            sudo dnf install -yq --setopt=debuglevel=0 "${hypr_deps[@]}"
    fi

    systemctl --user enable --now pipewire.service wireplumber.service &>/dev/null || true

    ok "Hyprland ecosystem ready"
}

# ========================== MODULE: FILES =====================================
run_files() {
    info "Stowing dotfiles..."

    if ! cmd_exists stow; then
        sudo dnf install -yq stow || { fail "Could not install stow"; return 1; }
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

    # Generate initial matugen colors
    if cmd_exists matugen && [ -f "$REPO_ROOT/wallpapers/Chisa.jpg" ]; then
        info "Generating initial matugen colors..."
        matugen image "$REPO_ROOT/wallpapers/Chisa.jpg" --prefer darkness && ok "matugen colors generated" \
            || warn "matugen failed — run manually"
    else
        warn "matugen: run manually after setting wallpaper"
    fi
}

# ========================== MAIN ==============================================
showhelp() {
    cat << 'EOF'

  Dotfiles Setup — Tuturu (Fedora)

  Usage: ./install-system.sh <command>

  Commands:
    full    Full system setup
    stow    Stow dotfiles only (re-run after pulling updates)

  Post-install:
    Run ./install-assets.sh for fonts, icons, cursors, and defaults.
    Run ./install-apps.sh for optional applications and development tools.

EOF
}

clear
prevent_root

case "${1:-help}" in
    full)
        sudo_init_keepalive
        trap sudo_stop_keepalive EXIT
        echo -e "${GREEN}${BOLD}=== Full System Setup ===${RESET}\n"
        run_rpmfusion && \
        run_packages && \
        run_appstream && \
        run_optimizations && \
        run_shell && \
        run_hypr && \
        run_files
        echo -e "\n${GREEN}${BOLD}=== Complete! ===${RESET}"
        echo -e "  Log out and select 'Hyprland' at login"
        echo -e "\n  ${CYAN}[i]${RESET} After first Hyprland login, run: ${BOLD}./install-assets.sh${RESET}"
        ;;
    stow)
        info "Stowing dotfiles..."
        run_files
        ok "Dotfiles stowed"
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
