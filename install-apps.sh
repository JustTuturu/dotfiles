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

# ========================== LAZYGIT ==========================================
install_lazygit() {
    info "Installing Lazygit from source"
    dnf_install golang || fail "Go installation failed"
    mkdir -p "$HOME/.local/bin" || fail "Could not create ~/.local/bin"
    GOBIN="$HOME/.local/bin" go install github.com/jesseduffield/lazygit@latest \
        || fail "Lazygit source installation failed"
    ok "Lazygit installed to ~/.local/bin"
}

# ========================== OFFICIAL APPS =====================================
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

# ========================== APPLICATIONS ======================================
install_apps() {
    install_obs
    install_blender
    install_btop
    install_brave
    install_zed
    install_bun
    install_uv
    install_herdr
    install_lazydocker
    install_lazygit
}

# ========================== MAIN =============================================
install_apps

echo -e "\n${GREEN}${BOLD}=== Applications and Tools Installed ===${RESET}"
