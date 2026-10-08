# Tuturu's Dotfiles

![Screenshot](wallpapers/Screenshot.png)

## Install

```bash
git clone https://github.com/JustTuturu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install-system.sh full
```

After the first Hyprland login:

```bash
./install-assets.sh
./install-apps.sh
```

Log out and select **Hyprland (uwsm-managed)** at login.

## Update

```bash
cd ~/dotfiles
./install-system.sh stow
```

## Software

- Terminal: [Ghostty](https://github.com/ghostty/ghostty)
- Shell: [Zsh](https://www.zsh.org/)
- Editor: [Zed](https://zed.dev/)
- Colorscheme: [Matugen](https://github.com/JustTuturu/matugen)

## Keybinds

`SUPER` is the Windows key.

| Keybind | Action |
| --- | --- |
| `SUPER + SPACE` | Terminal |
| `SUPER + B` | Browser |
| `SUPER + Y` | Yazi |
| `SUPER + TAB` | Launcher |
| `SUPER + Q` | Close window |
| `SUPER + Arrows` | Focus window |
| `SUPER + F` | Toggle floating |
| `SUPER + M` | Toggle fullscreen |
| `SUPER + SHIFT + S` | Area screenshot |
| `SUPER + L` | Lock |

## Theming

Wallpaper change (via Noctalia) regenerates all colors with matugen. To render manually:

```bash
matugen image ~/dotfiles/wallpapers/Chisa.jpg --prefer darkness
```
