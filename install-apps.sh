#!/usr/bin/env bash
# install-apps.sh — Optional applications and development tools
# Run AFTER install-system.sh.

set -euo pipefail

RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'
BOLD='\e[1m'; RESET='\e[0m'

info() { echo -e "\n  ${BLUE}[i]${RESET} ${BOLD}$*${RESET}"; }
ok()   { echo -e "  ${GREEN}[✓]${RESET} ${BOLD}$*${RESET}"; }
fail() { echo -e "  ${RED}[✗]${RESET} ${BOLD}$*${RESET}" && exit 1; }

cmd_exists() { command -v "$1" &>/dev/null; }

# Keep common DNF behavior in one place.
DNF_ARGS=(-yq --setopt=install_weak_deps=False)

dnf_install() {
    sudo dnf install "${DNF_ARGS[@]}" "$@"
}

# ========================== BRAVE ============================================
install_brave() {
    info "Installing Brave Browser"
    dnf_install dnf-plugins-core
    sudo dnf config-manager addrepo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    dnf_install brave-origin
    ok "Brave installed"
}

# ========================== ZED ==============================================
install_zed() {
    if cmd_exists zed; then ok "Zed already installed"; return; fi
    info "Installing Zed"
    curl -f https://zed.dev/install.sh | sh || fail "Zed installation failed"
    ok "Zed installed"
}

# ========================== HERDR ============================================
install_herdr() {
    info "Installing Herdr"
    curl -fsSL https://herdr.dev/install.sh | sh || fail "Herdr installation failed"
    ok "Herdr installed"
}

# ========================== BUN ==============================================
install_bun() {
    info "Installing Bun"
    curl -fsSL https://bun.com/install | bash || fail "Bun installation failed"
    ok "Bun installed"
}

# ========================== UV ===============================================
install_uv() {
    if cmd_exists uv; then ok "UV already installed"; return; fi
    info "Installing UV"
    curl -LsSf https://astral.sh/uv/install.sh | sh || fail "UV installation failed"
    ok "UV installed"
}

# ========================== LAZYDOCKER =======================================
install_lazydocker() {
    info "Installing Lazydocker"
    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash \
        || fail "Lazydocker installation failed"
    ok "Lazydocker installed"
}

# ========================== DNF PACKAGE HELPER ===============================
prompt_dnf_package() {
    local group="$1"
    local pkg="$2"

    info "${group}: ${pkg}"
    echo -ne "  Install ${BOLD}${pkg}${RESET}? [y/N] "
    read -r reply

    if [[ "${reply}" =~ ^[Yy]$ ]]; then
        dnf_install "${pkg}"
        ok "${pkg} installed"
    else
        info "Skipped ${pkg}"
    fi
}

# ========================== DEV TOOLS ================================
install_dev_tools() {
    local -a dev_tools=(gcc gcc-c++ make cmake python3-devel)

    info "Development tools"
    echo -ne "  Install all development tools (${dev_tools[*]})? [y/N] "
    read -r reply

    if [[ "${reply}" =~ ^[Yy]$ ]]; then
        dnf_install "${dev_tools[@]}"
        ok "Development tools installed"
    else
        info "Skipped development tools"
    fi
}

# ========================== OFICIAL APP ============================
install_obs() { prompt_dnf_package "Installing OBS Studio" obs-studio; }
install_blender() { prompt_dnf_package "Installing Blender" blender; }
install_btop() { prompt_dnf_package "Installing btop" btop; }
install_qt6ct() { prompt_dnf_package "Installing qt6ct" qt6ct; }


# ========================== APPLICATIONS ======================================
install_apps() {
    install_obs
    install_blender
    install_btop
    install_qt6ct
    install_discord
    install_brave
    install_zed
    install_bun
    install_uv
    install_herdr
    install_lazydocker
}

# ========================== MAIN =============================================
case "${1:-all}" in
    all)
        install_dev_tools
        install_apps
        ;;
    dev)
        install_dev_tools
        ;;
    apps)
        install_apps
        ;;
    *)
        echo "Usage: ./install-apps.sh [dev|apps]"
        exit 1
        ;;
esac

echo -e "\n${GREEN}${BOLD}=== Applications Installed ===${RESET}"
