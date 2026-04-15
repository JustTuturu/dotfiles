#!/usr/bin/env bash
# install-fonts.sh — install user fonts needed by this dotfiles setup

set -euo pipefail

FONT_DIR="${HOME}/.local/share/fonts"
TEMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

if fc-list | grep -qi "JetBrainsMono.*Nerd"; then
    echo "JetBrains Mono Nerd Font already installed"
    exit 0
fi

mkdir -p "${FONT_DIR}"

FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
ARCHIVE_PATH="${TEMP_DIR}/JetBrainsMono.tar.xz"

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${FONT_URL}" -o "${ARCHIVE_PATH}"
elif command -v wget >/dev/null 2>&1; then
    wget -q "${FONT_URL}" -O "${ARCHIVE_PATH}"
else
    echo "Neither curl nor wget is available" >&2
    exit 1
fi

tar -xf "${ARCHIVE_PATH}" -C "${TEMP_DIR}"
find "${TEMP_DIR}" -type f -name "*.ttf" -exec mv -f {} "${FONT_DIR}/" \;

fc-cache -f "${FONT_DIR}" >/dev/null 2>&1 || fc-cache -f >/dev/null 2>&1

echo "JetBrains Mono Nerd Font installed"
