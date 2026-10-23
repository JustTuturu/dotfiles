#!/usr/bin/env bash
# install.sh — Tuturu's dotfiles installer (Fedora + Hyprland)
#
# Run straight on a fresh machine
#   curl -fsSL https://raw.githubusercontent.com/JustTuturu/dotfiles/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- dotfiles

set -euo pipefail

# ========================== FLAGS ============================================
ASSUME_YES=0
_args=()
for _arg in "$@"; do
    case "${_arg}" in
        -y|--yes) ASSUME_YES=1 ;;
        *) _args+=("${_arg}") ;;
    esac
done
if (( ${#_args[@]} )); then set -- "${_args[@]}"; else set --; fi
unset _arg _args

# ========================== COLORS & UTILITIES ==============================
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'
BOLD='\e[1m'; RESET='\e[0m'

cmd_exists() { command -v "$1" &>/dev/null; }

# ========================== UI: GUM (OPTIONAL) ==============================
# Every helper falls back to plain ANSI output when gum is missing or there is
# no terminal, so `curl ... | bash` and CI runs keep working unchanged.
HAVE_GUM=0
HAVE_TTY=0
cmd_exists gum && HAVE_GUM=1
( : </dev/tty ) 2>/dev/null && HAVE_TTY=1

ui_style()    { [[ ${HAVE_GUM} -eq 1 && -t 1 ]]; }
# gum draws its widgets on /dev/tty, so prompts also work inside $(...).
ui_interact() { [[ ${HAVE_GUM} -eq 1 && ${HAVE_TTY} -eq 1 ]]; }

info() {
    if ui_style; then
        gum style --foreground 4 --bold --margin "1 0 0 0" "  [i] $*"
    else
        echo -e "\n  ${BLUE}[i]${RESET} ${BOLD}$*${RESET}"
    fi
}
ok() {
    if ui_style; then
        gum style --foreground 2 --bold "  [✓] $*"
    else
        echo -e "  ${GREEN}[✓]${RESET} ${BOLD}$*${RESET}"
    fi
}
warn() {
    if ui_style; then
        gum style --foreground 3 --bold "  [!] $*"
    else
        echo -e "  ${YELLOW}[!]${RESET} ${BOLD}$*${RESET}"
    fi
}
fail() {
    if ui_style; then
        gum style --foreground 1 --bold "  [✗] $*"
    else
        echo -e "  ${RED}[✗]${RESET} ${BOLD}$*${RESET}"
    fi
    exit 1
}

# Styled section heading
title() {
    if ui_style; then
        gum style --border rounded --border-foreground 5 --foreground 5 \
            --padding "0 2" --margin "1 0" "$*"
    else
        echo -e "\n${BOLD}=== $* ===${RESET}"
    fi
}

# Confirm an action. -y/--yes and non-interactive runs proceed silently.
ui_confirm() {
    local prompt="$1" default="${2:-no}"
    [[ ${ASSUME_YES} -eq 1 ]] && return 0
    ui_interact || return 0
    gum confirm --default="${default}" "${prompt}"
}

# Pick one option from a list; returns 1 when no interactive gum is available.
ui_choose() {
    local header="$1"; shift
    ui_interact || return 1
    gum choose --header="${header}" --height=8 "$@"
}

# Run a normally-silent command behind a spinner.
ui_spin() {
    local title="$1"; shift
    [[ "${1:-}" == "--" ]] && shift
    if ui_interact; then
        gum spin --spinner dot --title "${title}" --show-error -- "$@"
    else
        "$@"
    fi
}

all_present() {
    local dir="$1"; shift
    local f
    for f in "$@"; do [[ -f "${dir}/${f}" ]] || return 1; done
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# ========================== SELF-BOOTSTRAP ===================================
# When piped via curl there is no local repo — clone it and re-exec.
if [[ ! -f "${REPO_ROOT}/packages/dnf.txt" ]]; then
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

# ========================== MODULE: FILES (COPY) ==============================
run_files() {
    info "Copying dotfiles..."

    local cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
    local source_config="$REPO_ROOT/.config"
    local source_zshrc="$REPO_ROOT/zsh/.zshrc"
    local backup_dir=""
    local count=0
    local failed=0
    local source relative destination

    if [[ ! -d "$source_config" ]]; then
        fail "Missing $source_config"
    fi

    backup_file() {
        local file="$1" target="$2" backup_relative
        [[ -e "$target" && ! -L "$target" ]] || return 0
        if [[ -f "$target" ]] && cmp -s -- "$file" "$target"; then
            return 0
        fi
        if [[ -z "$backup_dir" ]]; then
            backup_dir="$(mktemp -d "$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
        fi
        backup_relative="${target#"$HOME"/}"
        mkdir -p "$backup_dir/$(dirname -- "$backup_relative")"
        cp -a -- "$target" "$backup_dir/$backup_relative"
    }

    copy_file() {
        local file="$1" target="$2" dir tmp
        dir="$(dirname -- "$target")"
        mkdir -p "$dir"
        if ! tmp="$(mktemp "$dir/.copy.XXXXXX")"; then
            warn "Could not create a temporary file in $dir"
            failed=$((failed + 1))
            return
        fi
        if cp -a -- "$file" "$tmp" && mv -f -- "$tmp" "$target"; then
            count=$((count + 1))
        else
            rm -f -- "$tmp"
            warn "Could not copy $file"
            failed=$((failed + 1))
        fi
    }

    while IFS= read -r -d '' source; do
        relative="${source#"$source_config/"}"
        destination="$cfg/$relative"
        backup_file "$source" "$destination"
        copy_file "$source" "$destination"
    done < <(find "$source_config" -type f -print0)

    if [[ -f "$source_zshrc" ]]; then
        backup_file "$source_zshrc" "$HOME/.zshrc"
        copy_file "$source_zshrc" "$HOME/.zshrc"
    else
        warn "Missing $source_zshrc"
        failed=$((failed + 1))
    fi

    ok "Copied $count files to $cfg and $HOME/.zshrc"
    [[ -n "$backup_dir" ]] && warn "Changed files backed up to $backup_dir"
    [ "$failed" -gt 0 ] && warn "$failed file(s) failed to copy"

    if cmd_exists matugen && [ -f "$REPO_ROOT/wallpapers/Chisa.jpg" ]; then
        info "Generating initial matugen colors..."
        if ui_spin "Generating matugen colors" -- matugen image "$REPO_ROOT/wallpapers/Chisa.jpg" --prefer darkness; then
            ok "matugen colors generated"
        else
            warn "matugen failed — run manually"
        fi
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

    ui_spin "Downloading JetBrains Mono" -- download \
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

        if ui_spin "Downloading ${name}" -- download "$url" "${FONT_DIR}/${name}"; then
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
    if ! ui_spin "Downloading ${theme}" -- download \
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
    ui_spin "Cloning Tela icon theme" -- git clone --depth 1 "$repo" "$clone_dir" \
        && ui_spin "Installing Tela icon theme" -- "$clone_dir/install.sh"

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

  Usage: ./install.sh [command] [-y|--yes]

  Commands:
    full      Full setup: system + assets + apps (default)
    dotfiles  Copy dotfiles only (re-run after pulling updates)
    menu      Pick a task in a gum menu (interactive)

  Options:
    -y, --yes Skip confirmation prompts

  Fresh machine (no clone needed):
    curl -fsSL https://raw.githubusercontent.com/JustTuturu/dotfiles/main/install.sh | bash

EOF
}

clear
prevent_root

COMMAND="${1:-full}"
if [[ "${COMMAND}" == "menu" ]]; then
    if ! ui_interact; then
        warn "menu needs an interactive terminal with gum installed"
        showhelp
        exit 1
    fi
    COMMAND="$(ui_choose "Tuturu dotfiles — what should run?" full dotfiles)" || exit 0
fi

case "${COMMAND}" in
    full)
        title "Full System Setup"
        ui_confirm "Run the full setup (system + assets + apps)?" yes || { echo "Aborted."; exit 0; }
        sudo_init_keepalive
        run_system
        run_assets
        install_apps
        title "Complete!"
        echo -e "  Log out and select 'Hyprland' at login"
        ;;
    dotfiles)
        run_files
        ok "Dotfiles copied"
        ;;
    help|--help|-h)
        showhelp
        ;;
    *)
        echo -e "${RED}Unknown command: ${COMMAND}${RESET}"
        showhelp
        exit 1
        ;;
esac
