# ─── ZSH CONFIG  ────────────────────────────────────
# Created by Tuturu
# Theme: matugen (Material You) — static fallbacks removed

# ─── History Configuration ───────────────────────────────────────
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_reduce_blanks

# ─── Completion Cache ────────────────────────────────────────────
ZSH_COMPDUMP="${HOME}/.cache/zsh/zcompdump-${ZSH_VERSION}"
mkdir -p "$(dirname "$ZSH_COMPDUMP")"

# ─── Zinit Plugin Manager ────────────────────────────────────────
ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# --- Color Theme (MUST be before syntax-highlight plugin) ---
[[ -f ~/.config/matugen/generated/zsh-highlight.zsh ]] && source ~/.config/matugen/generated/zsh-highlight.zsh
[[ -f ~/.config/matugen/generated/zsh-fzf-colors.zsh ]] && source ~/.config/matugen/generated/zsh-fzf-colors.zsh

# ─── Canonical fzf theme (Ghostty / Matugen palette) ─────────────
# Overrides matugen's fzf colors so every fzf pane — ctrl-r, ctrl-t, z,
# fzf-tab, and the zoxide popup inside yazi — uses ONE consistent scheme
# with a visible border, instead of a near-black slab with no frame.
export FZF_DEFAULT_OPTS=" \
  --no-border \
  --color=bg+:#29292f \
  --color=fg:#e4e1e9 \
  --color=fg+:#e4e1e9 \
  --color=hl:#ffb4ab \
  --color=hl+:#ffb4ab \
  --color=header:#ffb4ab \
  --color=info:#e0e0f9 \
  --color=prompt:#e0e0f9 \
  --color=pointer:#dfe0ff \
  --color=spinner:#dfe0ff \
  --color=marker:#e0e0f9 \
  --color=label:#e4e1e9 \
  --color=preview-fg:#e4e1e9"
export FZF_TAB_COLORS="fg:#e4e1e9,bg+:rgba(255,255,255,0.05),hl:#ffb4ab,fg+:#e4e1e9,hl+:#ffb4ab,info:#e0e0f9,prompt:#e0e0f9,pointer:#dfe0ff,marker:#ffb4ab,header:#ffb4ab"

# Core plugin installation
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions

# Deferred plugins (speeds up shell startup)
zinit ice wait'0' lucid
zinit light zsh-users/zsh-completions

zinit ice wait'0' lucid
zinit light Aloxaf/fzf-tab

# ─── fzf-tab style (blur + pink) ─────────────────────────────────
zstyle ':fzf-tab:*' fzf-flags --height=40% --no-border
zstyle ':fzf-tab:*' switch-group ',' "'"

zstyle ':completion:*:descriptions' format '%F{pink}%B%S ■ %s%b%f'
zstyle ':fzf-tab:*' preview-window right:50%:border-rounded
zstyle ':fzf-tab:complete:_zoxide:*' preview-window hidden

zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons --color=always --group-directories-first $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza --icons --color=always --group-directories-first $realpath'
zstyle ':fzf-tab:complete:cat:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || eza --icons --color=always $realpath'

zinit ice wait'0' lucid
zinit snippet OMZ::lib/functions.zsh
zinit snippet OMZ::lib/directories.zsh
zinit snippet OMZP::extract
zinit snippet OMZP::sudo
zinit snippet OMZP::git
zinit snippet OMZP::cp

# ─── Environment Variables ───────────────────────────────────────
export EDITOR="zed --wait"
export VISUAL="zed --wait"
export STARSHIP_CONFIG=$HOME/.config/matugen/generated/starship/starship.toml
export EZA_CONFIG_DIR=$HOME/.config/matugen/generated/eza
export NVM_DIR=$HOME/.nvm
export UV_LINK_MODE=copy
export PNPM_HOME="/home/suzu/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac

# ─── Tool Initializations ────────────────
# FZF (keybindings + completion)
eval "$(fzf --zsh)"
export FZF_DEFAULT_COMMAND='find . -maxdepth 2 -not -path "*/.*"'

# Zoxide popup inside Yazi (fzf child): same canonical palette as global
# fzf. Appended LAST in the zoxide preset's _ZO_FZF_OPTS, so it wins.
export YAZI_ZOXIDE_OPTS=" \
  --no-border \
  --no-scrollbar \
  --color=bg+:#29292f \
  --color=fg:#e4e1e9 \
  --color=fg+:#e4e1e9 \
  --color=hl:#ffb4ab \
  --color=hl+:#ffb4ab \
  --color=header:#ffb4ab \
  --color=info:#e0e0f9 \
  --color=prompt:#e0e0f9 \
  --color=pointer:#dfe0ff \
  --color=spinner:#dfe0ff \
  --color=marker:#e0e0f9"

# Zoxide
eval "$(zoxide init zsh)"

# Lazy NVM (loads on first use)
nvm() {
    unset -f nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm "$@"
}

# UV
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Starship (matugen-generated)
eval "$(starship init zsh)"

# Python cache
export PYTHONPYCACHEPREFIX=~/.cache/pycache

# Yazi shell wrapper
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# ─── Aliases ─────────────────────────────────────────────────────
alias disk='z /mnt/EVO990'
alias zz='z ~'
alias ls='eza --icons --color=always --group-directories-first'
alias ll='eza -lh -a --no-filesize --icons --color=always --git --group-directories-first'
alias la='eza -a --icons --git'
alias lt='eza --tree --icons'
alias yz='yazi'
alias yy='y'
alias s='sudo'
alias se='sudoedit'
alias b='bat'
alias lzd='lazydocker'
alias lzg='lazygit'
alias spotify='spotify_player'

# opencode
export PATH=/home/suzu/.opencode/bin:$PATH

# bun completions
[ -s "/home/suzu/.bun/_bun" ] && source "/home/suzu/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
