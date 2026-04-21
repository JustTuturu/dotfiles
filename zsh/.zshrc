# ─── ZSH CONFIG  ────────────────────────────────────
# Created by Tuturu

# ─── History Configuration ───────────────────────────────────────
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory

# ─── Zinit Plugin Manager ────────────────────────────────────────-----
ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# --- Color Theme  ------------------------------------------------------
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

# ─── Environment Variables ───────────────────────────────────────---
export EDITOR="zed --wait"
export VISUAL="zed --wait"
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
export EZA_CONFIG_DIR="$HOME/.config/eza"
export NVM_DIR="$HOME/.nvm"
export PATH="$HOME/.hermes/node/bin:$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# ─── Tool Initializations ────────────────-----------------------------
# FZF
eval "$(fzf --zsh)"

# Zoxide
eval "$(zoxide init zsh)"

# NVM & UV setup
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env" 

# Starship
eval "$(starship init zsh)" 

# Yazi
# Shell wrapper
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"

# ─── Aliases ─────────────────────────────────────────────────────-------
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
