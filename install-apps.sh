#!/usr/bin/env bash
# install-apps.sh — Optional applications and development tools
# Run AFTER install-system.sh.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="${REPO_ROOT}/packages"

RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'
BOLD='\e[1m'; RESET='\e[0m'

info() { echo -e "\n  ${BLUE}[i]${RESET} ${BOLD}$*${RESET}"; }
ok()   { echo -e "  ${GREEN}[✓]${RESET} ${BOLD}$*${RESET}"; }
fail() { echo -e "  ${RED}[✗]${RESET} ${BOLD}$*${RESET}" && exit 1; }

cmd_exists() { command -v "$1" &>/dev/null; }

# ========================== PACKAGE HELPERS ==================================
read_packages() {
    local file="$1"
    local -n arr="$2"
    arr=()
    [[ -f "${file}" ]] || { info "Package list not found: ${file}"; return 1; }
    while IFS= read -r line; do
        [[ "${line}" =~ ^\s*$ || "${line}" =~ ^\s*# ]] && continue
        for pkg in ${line}; do arr+=("${pkg}"); done
    done < "${file}"
}

# ========================== BRAVE ============================================
install_brave() {
    info "Installing Brave Browser"
    sudo dnf install -yq --setopt=debuglevel=0 dnf-plugins-core
    sudo dnf config-manager addrepo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo dnf install -yq --setopt=debuglevel=0 brave-origin
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

# ========================== OPTIONAL PACKAGES ================================
install_optional() {
    local -a optional_deps
    read_packages "${PKG_DIR}/optional.txt" optional_deps || return 0
    info "Optional packages available"

    local -a to_install=()
    for pkg in "${optional_deps[@]}"; do
        echo -ne "  Install ${BOLD}${pkg}${RESET}? [y/N] "
        read -r reply
        [[ "${reply}" =~ ^[Yy]$ ]] && to_install+=("${pkg}")
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        sudo dnf install -yq --setopt=install_weak_deps=False "${to_install[@]}"
        ok "Optional packages installed"
    else
        info "No optional packages selected"
    fi
}

# ========================== MAIN =============================================
if [[ $# -gt 0 ]]; then
    echo "Usage: ./install-apps.sh"
    exit 1
fi

install_optional
install_brave
install_zed
install_bun
install_uv
install_herdr
install_lazydocker

echo -e "\n${GREEN}${BOLD}=== Applications Installed ===${RESET}"
