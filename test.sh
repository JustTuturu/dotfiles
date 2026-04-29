#!/usr/bin/env bash
# test.sh — Validate dotfiles integrity without installing anything
# Usage: ./test.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; BLUE='\e[34m'
BOLD='\e[1m'; RESET='\e[0m'

passed=0
failed=0

ok()   { echo -e "  ${GREEN}[✓]${RESET} $*"; passed=$((passed + 1)); }
warn() { echo -e "  ${YELLOW}[!]${RESET} $*"; failed=$((failed + 1)); }
fail() { echo -e "  ${RED}[✗]${RESET} $*"; failed=$((failed + 1)); }
info() { echo -e "\n${BLUE}[i]${RESET} ${BOLD}$*${RESET}"; }

# ─── SYNTAX CHECKS ───────────────────────────────────────────────

info "Checking script syntax"

if bash -n "${REPO_ROOT}/install.sh" 2>/dev/null; then
    ok "install.sh syntax is valid"
else
    fail "install.sh has syntax errors"
fi

# ─── PACKAGE LISTS ───────────────────────────────────────────────

info "Checking package lists"

for list in copr.txt dnf.txt hypr.txt optional.txt stow.txt; do
    if [[ -f "${REPO_ROOT}/packages/${list}" ]]; then
        ok "packages/${list} exists"
    else
        fail "packages/${list} is missing"
    fi
done

# ─── STOW PACKAGES ───────────────────────────────────────────────

info "Checking stow packages exist"

while IFS= read -r pkg; do
    [[ "${pkg}" =~ ^\s*$ || "${pkg}" =~ ^\s*# ]] && continue
    if [[ -d "${REPO_ROOT}/${pkg}" ]]; then
        ok "package directory: ${pkg}/"
    else
        fail "package directory missing: ${pkg}/"
    fi
done < "${REPO_ROOT}/packages/stow.txt"

# ─── DUPLICATE ENTRIES ───────────────────────────────────────────

info "Checking for duplicate entries"

for list in copr.txt dnf.txt hypr.txt optional.txt stow.txt; do
    dups=$(grep -v '^\s*#' "${REPO_ROOT}/packages/${list}" 2>/dev/null | grep -v '^\s*$' | sort | uniq -d)
    if [[ -z "${dups}" ]]; then
        ok "packages/${list} has no duplicates"
    else
        fail "packages/${list} has duplicates: ${dups}"
    fi
done

# ─── MATUGEN TEMPLATES ───────────────────────────────────────────

info "Checking matugen templates"

if [[ -f "${REPO_ROOT}/matugen/.config/matugen/config.toml" ]]; then
    ok "matugen config.toml exists"
else
    fail "matugen config.toml missing"
fi

# Extract template input paths from config.toml
while IFS= read -r line; do
    [[ "${line}" =~ input_path ]] || continue
    path_raw="${line#*= }"
    path="${path_raw//\"/}"
    path="${path/#\~/${HOME}}"
    # Map ~/.config/matugen/templates/ -> ${REPO_ROOT}/matugen/.config/matugen/templates/
    if [[ "${path}" == "${HOME}/.config/matugen/templates/"* ]]; then
        rel="${path#${HOME}/.config/matugen/templates/}"
        repo_path="${REPO_ROOT}/matugen/.config/matugen/templates/${rel}"
        if [[ -f "${repo_path}" ]]; then
            ok "template exists: ${rel}"
        else
            fail "template missing: ${rel}"
        fi
    fi
done < "${REPO_ROOT}/matugen/.config/matugen/config.toml"

# ─── HYPRLAND CONFIG SOURCES ─────────────────────────────────────

info "Checking Hyprland config sources"

hypr_conf="${REPO_ROOT}/hypr/.config/hypr/hyprland.conf"
if [[ -f "${hypr_conf}" ]]; then
    ok "hyprland.conf exists"
else
    fail "hyprland.conf missing"
fi

while IFS= read -r line; do
    [[ "${line}" =~ ^source ]] || continue
    src="${line#source = }"
    src="${src/#\~/${HOME}}"
    # Convert to repo-relative if under ~/.config
    if [[ "${src}" == "${HOME}/.config/hypr/"* ]]; then
        rel="${src#${HOME}/.config/hypr/}"
        repo_src="${REPO_ROOT}/hypr/.config/hypr/${rel}"
        if [[ -f "${repo_src}" ]]; then
            ok "hypr source exists: ${rel}"
        else
            fail "hypr source missing: ${rel}"
        fi
    elif [[ "${src}" == "${HOME}/.config/matugen/"* ]]; then
        ok "hypr source (generated): ${src##*/}"
    fi
done < "${hypr_conf}"

# ─── HYPLOCK CONFIG ──────────────────────────────────────────────

info "Checking hyprlock"

hyprlock_conf="${REPO_ROOT}/hypr/.config/hypr/hyprlock.conf"
if [[ -f "${hyprlock_conf}" ]]; then
    if grep -q 'source = ~/.config/matugen/generated/hyprlock-colors.conf' "${hyprlock_conf}"; then
        ok "hyprlock sources matugen colors"
    else
        warn "hyprlock missing matugen source line"
    fi
else
    fail "hyprlock.conf missing"
fi

# ─── ZSH CONFIG ──────────────────────────────────────────────────

info "Checking Zsh config"

zshrc="${REPO_ROOT}/zsh/.zshrc"
if [[ -f "${zshrc}" ]]; then
    ok ".zshrc exists"
else
    fail ".zshrc missing"
fi

if zsh -n "${zshrc}" 2>/dev/null; then
    ok ".zshrc syntax is valid"
else
    warn ".zshrc has syntax issues (may be false positive due to zinit)"
fi

# Check for common issues
if grep -q 'alias bat=.cat.' "${zshrc}" 2>/dev/null; then
    fail ".zshrc contains 'alias bat=cat'"
else
    ok ".zshrc: no bat=cat alias"
fi

if grep -q 'source ~/.fzf.zsh' "${zshrc}" 2>/dev/null; then
    warn ".zshrc still sources ~/.fzf.zsh (redundant with eval)"
else
    ok ".zshrc: no redundant fzf source"
fi

if grep -q 'nvm()' "${zshrc}" 2>/dev/null; then
    ok ".zshrc: NVM is lazy-loaded"
else
    warn ".zshrc: NVM may not be lazy-loaded"
fi

# ─── GHOSTTY CONFIG ──────────────────────────────────────────────

info "Checking Ghostty config"

ghostty_conf="${REPO_ROOT}/ghostty/.config/ghostty/config.ghostty"
if [[ -f "${ghostty_conf}" ]]; then
    if grep -q 'config-file = ~/.config/matugen/generated/ghostty-colors.conf' "${ghostty_conf}"; then
        ok "Ghostty includes matugen colors"
    else
        warn "Ghostty missing matugen config-file include"
    fi
else
    fail "Ghostty config missing"
fi

# ─── AUTOSTART DUPLICATES ────────────────────────────────────────

info "Checking autostart duplicates"

autostart_conf="${REPO_ROOT}/hypr/.config/hypr/conf/autostart.conf"
if [[ -f "${autostart_conf}" ]]; then
    dups=$(grep -o 'exec-once.*' "${autostart_conf}" | sort | uniq -d)
    if [[ -z "${dups}" ]]; then
        ok "autostart.conf: no duplicate exec-once lines"
    else
        fail "autostart.conf has duplicates:"
        echo "${dups}" | sed 's/^/       /'
    fi
else
    fail "autostart.conf missing"
fi

# ─── EZA THEME ───────────────────────────────────────────────────

info "Checking Eza theme"

eza_theme="${REPO_ROOT}/eza/.config/eza/theme.yml"
if [[ -f "${eza_theme}" ]]; then
    if grep -q '{{colors.' "${eza_theme}" 2>/dev/null; then
        warn "Eza theme contains mustache syntax (should be static fallback)"
    else
        ok "Eza theme is static fallback (matugen will overwrite at runtime)"
    fi
else
    fail "Eza theme.yml missing"
fi

# ─── STARSHIP ────────────────────────────────────────────────────

info "Checking Starship"

if [[ -f "${REPO_ROOT}/starship/.config/starship.toml" ]]; then
    warn "Static starship.toml still exists in repo (should be matugen-generated only)"
else
    ok "No static starship.toml in repo (generated by matugen)"
fi

# ─── SUMMARY ─────────────────────────────────────────────────────

info "Results: ${passed} passed, ${failed} failed"

if [[ "${failed}" -gt 0 ]]; then
    exit 1
fi
