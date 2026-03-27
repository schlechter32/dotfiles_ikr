# Make nice tree
#
function cfp() {
  realpath -- "$1" | xclip -selection clipboard
}
function lt() {
  if [ -z "$1" ]; then
    eza --icons -T -L 2
  else
    eza --icons -T -L "$1"
  fi
}

function ya() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    # echo $cwd
		cd "$cwd"
	fi
	rm -f -- "$tmp"

}

function fsshmap() {
  echo -n "-L 1$1:127.0.0.1:$1 " > $HOME/sh/sshports.txt
  for ((i=($1+1);i<$2;i++))
  do
    echo -n "-L 1$i:127.0.0.1:$i " >> $HOME/sh/sshports.txt
  done
  line=$(head -n 1 $HOME/sh/sshports.txt)
  cline="nsh "$3" "$line
  echo $cline
  eval $cline
}
function tnl {
  TUNNEL="nsh -N"
  echo Port forwarding for ports:
  for i in ${@:2}
  do
    echo " - $i"
    TUNNEL="$TUNNEL -L $i"
    # echo $TUNNEL
  done
  TUNNEL="$TUNNEL $1"
  eval "$TUNNEL &"
  PID=$!
  alias tnlkill="kill $PID && unalias tnlkill"
}
nsh-add() {
  local key_name="$1"
  [[ -n "$key_name" ]] || return 1
  pass show "ssh/$key_name" | ssh-add -
}
function tc {
  local GHOSTTY_DIR="$HOME/dotfiles/.config/ghostty"
  local selected

  selected="$(tv \
    --source-command="fd -L --type f --exclude config --base-directory '$GHOSTTY_DIR'" \
    --source-display="{}" \
    --source-output="{}" \
    --preview-command="cat '$GHOSTTY_DIR'/{}")" || return

  [[ -n "$selected" ]] || return
  sed -i '' "s:\(config-file = \$HOME/.config/ghostty\)/.*:\1/$selected:" "$GHOSTTY_DIR/config" \
    && osascript -so -e 'tell application "Ghostty" to activate' -e 'tell application "System Events" to keystroke "," using {command down, shift down}'
}

# List devpod workspaces on a remote host
# Usage: devpod-remote-list [host]
devpod-remote-list() {
  local host="${1:-ecobra3}"
  ssh "$host" devpod list --output json 2>/dev/null | jq -r '.[].id'
}

# Generate SSH config block for a remote devpod workspace
# Usage: devpod-remote-ssh-config <workspace-id> [host]
devpod-remote-ssh-config() {
  local workspace="$1"
  local host="${2:-ecobra3}"
  cat <<SSHCONF
Host ${workspace}.devpod
  ForwardAgent yes
  LogLevel error
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  ProxyCommand ssh ${host} devpod ssh --stdio --context default --user dev ${workspace} --workdir "/workspace"
  User dev
SSHCONF
}
