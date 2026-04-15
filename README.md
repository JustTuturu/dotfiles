# [ Tuturu's dotfiles ]

<p align="center">
  <a href="https://github.com/Tut-Tut-Tut/dotfiles/commits">
    <img src="https://img.shields.io/github/last-commit/Tut-Tut-Tut/dotfiles?style=for-the-badge&labelColor=0C0D11&color=A8AEFF&logo=git&logoColor=FFFFFF&label=commit" alt="Last commit" />
  </a>
  <a href="https://github.com/Tut-Tut-Tut/dotfiles/stargazers">
    <img src="https://img.shields.io/github/stars/Tut-Tut-Tut/dotfiles?style=for-the-badge&labelColor=0C0D11&color=A8AEFF&logo=github&logoColor=FFFFFF" alt="GitHub stars" />
  </a>
  <a href="https://github.com/Tut-Tut-Tut/dotfiles">
    <img src="https://img.shields.io/github/repo-size/Tut-Tut-Tut/dotfiles?style=for-the-badge&labelColor=0C0D11&color=A8AEFF&logo=github&logoColor=FFFFFF&label=size" alt="Repo size" />
  </a>
  <a href="https://discord.gg/KZpH6GCfQF">
    <img src="https://img.shields.io/badge/discord-A8AEFF?style=for-the-badge&labelColor=0C0D11&logo=discord&logoColor=FFFFFF" alt="Discord" />
  </a>
</p>

<p><br/></p>

## 📁 Cấu trúc thư mục

```
~/dotfiles/
├── config/
│   ├── hypr/.config/hypr/         → ~/.config/hypr
│   ├── quickshell/.config/quickshell/  → ~/.config/quickshell
│   ├── rofi/.config/rofi/         → ~/.config/rofi
│   └── ... (các config khác)
└── scripts/
└── zsh/
```

## 🚀 Cách sử dụng Stow

### Stow toàn bộ configs

```bash
cd ~/dotfiles/config
stow -t ~ */        # Stow tất cả
```

### Stow từng config riêng lẻ

```bash
cd ~/dotfiles/config

# Stow một config
stow -t ~ hypr
stow -t ~ quickshell
stow -t ~ rofi

# Unstow (gỡ symlink)
stow -t ~ -D hypr

# Restow (gỡ rồi tạo lại)
stow -t ~ -R hypr
```

## ✅ Danh sách configs đã stow

| Config | Trạng thái |
|--------|-----------|
| colors | ✅ |
| eza | ✅ |
| fontconfig | ✅ |
| ghostty | ✅ |
| hypr | ✅ |
| matugen | ✅ |
| quickshell | ✅ |
| rofi | ✅ |
| starship | ✅ |
| themes | ✅ |
| tmux | ✅ |
| uv | ✅ |
| waybar | ✅ |
| wlogout | ✅ |
| yazi | ✅ |

## 🔍 Kiểm tra

```bash
# Xem tất cả symlinks trong ~/.config
ls -la ~/.config/ | grep "^l"

# Kiểm tra 1 config cụ thể
ls -la ~/.config/hypr
file ~/.config/hypr
```

## ⚠️ Lưu ý

- Luôn `cd ~/dotfiles/config` trước khi stow
- Dùng `-t ~` để target đúng vào home directory
- Nếu có conflicts, backup file cũ trước khi stow

## 📝 Script tự động

```bash
#!/bin/bash
# stow-all.sh - Stow tất cả configs

cd ~/dotfiles/config || exit 1

for dir in */; do
    echo "Stowing $dir..."
    stow -t ~ "$dir"
done

echo "Done!"
```
