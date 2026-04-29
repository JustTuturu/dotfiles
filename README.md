# Tuturu's Dotfiles

Fedora-based Hyprland dotfiles managed with **GNU Stow**. All color theming is driven by [**matugen**](https://github.com/InioX/matugen) from your wallpaper.

| Component | Choice |
|-----------|--------|
| OS | Fedora Linux |
| WM | Hyprland + UWSM |
| Shell | Zsh (Zinit) + Starship |
| Bar / Launcher | Noctalia (Quickshell) |
| Terminal | Ghostty |
| Editor | Zed |
| File Manager | Yazi |
| Theming | Matugen → dynamic colors |

## Quick Start

```bash
cd ~/dotfiles
./install.sh install
```

## Stow

```bash
# All packages
stow -t ~ $(cat packages/stow.txt)

# Single package
stow -t ~ hypr
stow -t ~ -D hypr   # unstow
stow -t ~ -R hypr   # restow
```

## Theming

Run matugen after changing wallpaper:

```bash
matugen image ~/Pictures/Wallpapers/wallpaper.jpg --prefer darkness
```

Matugen generates colors for: Hyprland, Ghostty, Eza, FZF, Zsh, Starship, Hyprlock, Rofi, Quickshell.

Static fallbacks: Tmux, Zed, Bat, Lazygit.
