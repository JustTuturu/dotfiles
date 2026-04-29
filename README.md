# Tuturu's Dotfiles

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

## Fresh Install

```bash
git clone https://github.com/JustTuturu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh install-full
```

Log out and select **Hyprland (UWSM)** at login.

## Update Dotfiles

After pulling updates or editing configs:

```bash
cd ~/dotfiles
./install.sh install
```

## Theming

Run matugen after changing wallpaper:

```bash
matugen image ~/Pictures/Wallpapers/wallpaper.jpg --prefer darkness
```
