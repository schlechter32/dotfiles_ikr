# $HOME/.juliaup/bin/julia --project=$TOOL_PATH --threads 1 -e "import RL_RSA_MDPs_study; RL_RSA_MDPs_study.ilpmain()"
# Add changes in submodules
# Aliases
# Commit changes in submodules
# Push changes in submodules
# Shell integrations
# SimTree find commands
# Update all submodules
# [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# alias ff='fzf --preview="bat --color=always --style=plain --line-range=:100000 {}" --bind "k:preview-up,j:preview-down,e:execute(bat --color=always --style=plain --line-range=:100000 {})"'
# alias ff='fzf --preview="bat --color=always --style=plain {}" --bind "k:preview-up,j:preview-down"'
# alias ff='fzf --preview=\"bat --color=always --style=plain {} --bind k:preview-up, j:preview-down\"'
# alias notionsync="python ~/source/notionsync/notionsync.py"
# eval "$(pyenv init -)"
# eval "$(pyenv virtualenv-init - | sed s/precmd/precwd/g)"
#find . -type d -name "Seed01" -exec test -e "{}/simtree.lock" \; -exec rm -rf {} +   
#find . -type d -name 'Seed01' -not -empty -exec sh -c '[ ! -e "$1/Export.log" ] && echo rm -rf "$1"' _ {} \;
# alias cpfp='realpath "$1" | xclip -sel -c'
alias ......="cd ../../.."
alias sl="ssh-add -l"
alias ....="cd ../.."
alias ..="cd .."
alias c9="nsh n9"
alias c="clear"
alias c='clear'
alias cal='chromium --app=https://outlook.live.com/calendar/0/view/week'
alias cf='cd "$(tv dirs)"'
alias ch='cat /sys/class/power_supply/BAT0/uevent' 
alias co="open -a 'Visual Studio Code'"
alias echopath="echo \"$PATH\" | tr ':' '\n'"
alias eof='exo-open "$(tv dotfiles-files)"'
alias ff='tv dotfiles-files'
alias finder="open -a finder"
alias git-submodule-push='git submodule foreach git push'
alias gsa='git submodule foreach git add .'
alias gsm='git submodule foreach git commit -am'
alias gsu='git submodule update --init --recursive'
alias hf='tv bash-history'
alias i="ish"
alias j="julia"
alias jo="JULIA_PKG_OFFLINE='true' julia "
alias jp="julia --project"
alias jpo="JULIA_PKG_OFFLINE='true' julia --project"
alias ka="sudo kanata --quiet --cfg ~/dotfiles/kanata.kbd&"
alias la='ls -a'
alias lg='lazygit'
alias ls="eza --icons --group --header --mounts --created "
alias ll="ls -l"
alias lla="ls -alh"
# alias ls='ls --color'
alias nhmail="mutt -f .IncomingMail.d/"
alias notionsync="uv run notionsync.py $HOME/secondBrain/05Zettelkasten"
alias or="v $HOME/secondBrain/00inbox/*.md"
alias sc="st cd"
alias s="ssh"
alias sde="setxkbmap de"
alias seu="setxkbmap eu"
alias sf="sf_script.sh"
alias smi="watch -n0.1 nvidia-smi"
alias studentproject="PoolEditor SPP"
alias studenttopics="PoolEditor SPT"
alias sudo='sudo '
alias ta='tmux attach-session -t "$(tv tmux-sessions)"'
alias tl='tv tmux-sessions'
alias to='tv projects'
alias v="nvim"
alias vf='v "$(tv dotfiles-files)"'
alias vim="nvim"
alias vim='nvim'
alias z="zellij"
alias za='zellij attach "$(tv zellij-sessions)"'
alias zl='tv zellij-sessions'
alias zo='tv projects --keybindings '\''enter="actions:zellij"'\'''

alias codex-auto='codex -a full-auto'
alias codex-local-auto='OLLAMA_BASE_URL=http://localhost:11434/v1 codex --provider
  ollama -m qwen3-coder-next:latest -a full-auto'


alias claude-auto='claude --dangerously-skip-permissions'
alias claude-local-auto='ANTHROPIC_AUTH_TOKEN=ollama
  ANTHROPIC_BASE_URL=http://localhost:11434 ANTHROPIC_API_KEY="" claude
  --dangerously-skip-permissions --model qwen3-coder-next:latest'
