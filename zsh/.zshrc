# ─── ZSH CONFIG  ────────────────────────────────────
# Created by Tuturu

# ─── History Configuration ───────────────────────────────────────
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory

# ─── Zinit Plugin Manager ────────────────────────────────────────
ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# --- Color Theme (MUST be before syntax-highlight plugin) ---
source ~/.config/matugen/generated/zsh-highlight.zsh
source ~/.config/matugen/generated/zsh-fzf-colors.zsh

# Core plugin installation
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab

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
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export PATH=$HOME/.hermes/node/bin:$PATH

# ─── Tool Initializations ────────────────
# FZF: Catppuccin Macchiato
eval "$(fzf --zsh)"
export FZF_DEFAULT_OPTS=" \
--color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
--color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
--color=marker:#b7bdf8,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796 \
--color=selected-bg:#494d64 \
--color=border:#363a4f,label:#cad3f5"
export FZF_TAB_COLORS='fg:#cad3f5,bg:#24273a,hl:#ed8796,min-height=5'

# Zoxide
eval "$(zoxide init zsh)"

# NVM & UV setup
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env" 

# Starship: Catppuccin Macchiato
eval "$(starship init zsh)" 


# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='find . -maxdepth 2 -not -path "*/.*"'

# Unikey
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx

# Cargo
export PATH="$HOME/.cargo/bin:$PATH"

# Yazi
# Shell wrapper
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Python cache
export PYTHONPYCACHEPREFIX=~/.cache/pycache

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
alias bat='cat'
alias yz='yazi'
alias s='sudo'
alias se='sudoedit'
alias yzhs='yz sftp://homeserver'
