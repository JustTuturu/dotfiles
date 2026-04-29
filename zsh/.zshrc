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

# Core plugin installation
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions

# Deferred plugins (speeds up shell startup)
zinit ice wait'0' lucid
zinit light zsh-users/zsh-completions

zinit ice wait'0' lucid
zinit light Aloxaf/fzf-tab

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
export STARSHIP_CONFIG=$HOME/.config/starship.toml
export EZA_CONFIG_DIR=$HOME/.config/eza
export NVM_DIR=$HOME/.nvm
export UV_LINK_MODE=copy
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.hermes/node/bin:$HOME/.cargo/bin:/usr/local/bin:$PATH"

# ─── Tool Initializations ────────────────
# FZF (keybindings + completion)
eval "$(fzf --zsh)"
export FZF_DEFAULT_COMMAND='find . -maxdepth 2 -not -path "*/.*"'

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

# Unikey
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx

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
alias e='cd /mnt/sata'
alias d='cd /mnt/nvme'
alias zz='z ~'
alias ls='eza --icons --color=always --group-directories-first'
alias ll='eza -lh -a --no-filesize --icons --color=always --git --group-directories-first'
alias la='eza -a --icons --git'
alias lt='eza --tree --icons'
alias zconfig='ag ~/.zshrc'
alias sconfig='ag ~/.config/starship/starship.toml'
alias yz='yazi'
alias yy='y'
alias s='sudo'
alias se='sudoedit'
