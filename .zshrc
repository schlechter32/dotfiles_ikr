export EDITOR=nvim
GPG_TTY=$(tty)
export GPG_TTY
# PATHS
source "$HOME/dotfiles/zsh/paths.zsh"
source "$HOME/dotfiles/zsh/homebrew.zsh"


export TMS_CONFIG_FILE="$HOME/.config/tms/config.toml"
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting
zinit light jeffreytse/zsh-vi-mode

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit
compinit

zinit cdreplay -q

source "$HOME/dotfiles/zsh/devpod.zsh"

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
setopt auto_cd

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'


source "$HOME/dotfiles/zsh/aliases.zsh"
source "$HOME/dotfiles/zsh/functions.zsh"
source "$HOME/dotfiles/zsh/ikrhosts.zsh"

if [[ $(uname) == "Darwin" ]]; then
    alias nsh="nsh-darwin-arm64" 
else
    alias nsh="nsh-linux-amd64" 
fi

# Shell integrations
eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"
eval "$(tv init zsh)"

autoload -Uz edit-command-line
zle -N edit-command-line

# Secrets
if [ -f "$HOME/.secrets" ]; then
source ~/.secrets
fi
# Shortcuts
function zvm_after_init() {
    bindkey '^p' history-search-backward
    bindkey '^n' history-search-forward
    bindkey '^[w' kill-region
    bindkey '^g' autosuggest-execute
    bindkey '^e' autosuggest-accept
    bindkey '^u' autosuggest-toggle

    bindkey '^R' tv-shell-history
    bindkey '^T' tv-smart-autocomplete
    bindkey -M viins '^R' tv-shell-history
    bindkey -M viins '^T' tv-smart-autocomplete
    bindkey -M vicmd '^R' tv-shell-history
    bindkey -M vicmd '^T' tv-smart-autocomplete
    bindkey '^X^E' edit-command-line
    bindkey -M viins '^X^E' edit-command-line
    bindkey -M vicmd '^X^E' edit-command-line
    # unbindkey '^T'
}
zvm_after_init
eval "$(uv generate-shell-completion zsh)"

# opencode
export PATH=/home/nclshrnk/.opencode/bin:$PATH
eval "$(tv init zsh)"
