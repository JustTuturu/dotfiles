<div align="center">
    
# Tuturu's Dotfiles 
Home of all my dotfiles    
</div>

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
</p>
<p><br/></p>

<p align="center">
  <img src="wallpapers/Screenshot.png" width="600" alt="Screenshot">
</p>



## How to install

```bash
git clone https://github.com/JustTuturu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install-system.sh full
```

`install-system.sh full` handles packages (dnf, COPR, RPM Fusion), system optimizations, and stows all configs. After the first Hyprland login, run the asset and application installers:

```bash
./install-assets.sh
./install-apps.sh
```

`install-assets.sh` installs fonts, icons, cursors, and desktop defaults. `install-apps.sh` installs optional applications and development tools. Fonts and cursors are fetched from public upstream sources (no `gh` CLI or authentication required).

Log out and select **Hyprland (uwsm-managed)** at login. UWSM owns the
Hyprland session and launches graphical applications as systemd user units.

For TTY login, the stowed `zsh/.zprofile` starts Hyprland through UWSM
automatically. If UWSM is unavailable on your Fedora repositories, install it
from the [upstream project](https://github.com/Vladimir-csp/uwsm) before
starting the session.

## Update dotfiles

My dotfiles are managed by [GNU Stow](https://www.gnu.org/software/stow/).
The system installer installs `stow` automatically when needed.

```bash
sudo dnf install stow
``` 

Then run `stow` to symlink the dotfiles:

```bash
cd ~/dotfiles
./install-system.sh stow
```

## Softwares

- Terminal: [Ghostty](https://github.com/ghostty/ghostty)
- Font: [JetBrains Mono](https://www.jetbrains.com/lp/mono/) (terminal/editor) · Inter + Literata (UI/reading) · LXGW WenKai Mono + Zen Kaku Gothic New (CJK)
- Colorscheme: [Matugen](https://github.com/JustTuturu/matugen)
- Shell: [Zsh](https://www.zsh.org/)
- Editor: [Zed](https://zed.dev/)
- Micro: terminal editor — **headless servers only** (`micro/.config/micro` with Matugen transparent theme; not used on the desktop, where Zed is the editor)
- Downloader: [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- IRC: [Halloy](https://halloy.chat/)

## Theming

matugen is the single source of truth for the palette. Noctalia owns the
wallpaper and fires its `[hooks] wallpaper_changed`, which runs
`~/.config/matugen/scripts/wallpaper-hook.sh`:

```
wallpaper change -> Noctalia hook -> wallpaper-hook.sh -> matugen image "$NOCTALIA_WALLPAPER_PATH" --prefer darkness
```

So changing the wallpaper regenerates every template; you never run matugen by
hand. Noctalia's own template rendering stays disabled (no `builtin_ids`, no
`community_ids`) so nothing else writes the same files.

The hook fires once per output connector, so `wallpaper-hook.sh` uses `flock`
plus a stamp file in `~/.local/state/matugen/` to collapse a two-monitor change
into a single matugen run.

To render manually:

```bash
matugen image ~/dotfiles/wallpapers/Chisa.jpg --prefer darkness
```

`--prefer` is required: the wallpaper has multiple candidate source colors and
matugen cannot prompt without a terminal.

Everything re-reads the generated files automatically except three apps, which
`wallpaper-hook.sh` nudges through `reload-apps.sh`:

- **Hyprland** — `~/.config/hypr/generated/colors.lua` is read when the config is
  parsed, so it gets `hyprctl reload`.
- **Ghostty** — does not reload its config on change, so it gets `SIGUSR2`
  (or a systemd unit reload when it runs as one).
- **btop** — reads its theme file at startup, so it gets `SIGUSR2`.

