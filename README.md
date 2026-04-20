# Tuturu's dotfiles

<p align="center">
  <a href="https://github.com/JustTuturu/dotfiles/commits">
    <img src="https://img.shields.io/github/last-commit/JustTuturu/dotfiles?style=for-the-badge&labelColor=0C0D11&color=A8AEFF&logo=git&logoColor=FFFFFF&label=commit" alt="Last commit" />
  </a>
  <a href="https://github.com/JustTuturu/dotfiles/stargazers">
    <img src="https://img.shields.io/github/stars/JustTuturu/dotfiles?style=for-the-badge&labelColor=0C0D11&color=A8AEFF&logo=github&logoColor=FFFFFF" alt="GitHub stars" />
  </a>
  <a href="https://github.com/JustTuturu/dotfiles">
    <img src="https://img.shields.io/github/repo-size/JustTuturu/dotfiles?style=for-the-badge&labelColor=0C0D11&color=A8AEFF&logo=github&logoColor=FFFFFF&label=size" alt="Repo size" />
  </a>
  <a href="https://discord.gg/KZpH6GCfQF">
    <img src="https://img.shields.io/badge/discord-A8AEFF?style=for-the-badge&labelColor=0C0D11&logo=discord&logoColor=FFFFFF" alt="Discord" />
  </a>
</p>

<p><br/></p>

## Directory Structure

```
~/dotfiles/
├── .config/
│   ├── eza/             → ~/.config/eza
│   ├── fastfetch/       → ~/.config/fastfetch
│   ├── fontconfig/      → ~/.config/fontconfig
│   ├── ghostty/         → ~/.config/ghostty
│   ├── hypr/            → ~/.config/hypr
│   ├── matugen/         → ~/.config/matugen
│   ├── starship/        → ~/.config/starship
│   ├── themes/          → ~/.config/themes
│   ├── tmux/            → ~/.config/tmux
│   ├── uv/              → ~/.config/uv
│   ├── wlogout/         → ~/.config/wlogout
│   ├── yazi/            → ~/.config/yazi
│   └── zed/             → ~/.config/zed
├── scripts/
│   ├── setup.sh
│   └── install-fonts.sh
└── zsh/
    └── .zshrc           → ~/.zshrc
```

## Usage (GNU Stow)

### Stow all configs

```bash
cd ~/dotfiles
stow -t ~ .config
stow -t ~ zsh
```

### Stow individual configs

```bash
cd ~/dotfiles

# Stow a config
stow -t ~ -d .config hypr
stow -t ~ -d .config ghostty
stow -t ~ -d .config yazi

# Stow zsh
stow -t ~ zsh

# Unstow (remove symlink)
stow -t ~ -d .config -D hypr

# Restow (remove then recreate)
stow -t ~ -d .config -R hypr
```

## Config List

| Config | Description |
|--------|-------------|
| eza | File listing theme |
| fastfetch | System info fetcher |
| fontconfig | Font configuration |
| ghostty | Terminal emulator |
| hypr | Hyprland window manager (hyprland, hypridle, hyprlock) |
| matugen | Material you color generator |
| starship | Shell prompt |
| themes | Zsh syntax highlighting theme |
| tmux | Terminal multiplexer |
| uv | Python package manager |
| wlogout | Logout menu |
| yazi | Terminal file manager |
| zed | Code editor |

## Verify Symlinks

```bash
# List all symlinks in ~/.config
ls -la ~/.config/ | grep "^l"

# Check a specific config
ls -la ~/.config/hypr
file ~/.config/hypr
```

## Notes

- Always `cd ~/dotfiles` before running stow
- Use `-t ~` to target your home directory
- If there are conflicts, back up the existing file before stowing
- The `quickshell` and `rofi` symlinks in ~/.config point outside this repo
