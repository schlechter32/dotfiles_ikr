# Self-heal: zellij stores plugin permissions in ~/.cache/zellij/permissions.kdl
# but caches get wiped (cluster cleanup, manual rm, zellij grant rewrites).
# Re-link from the dotfiles copy on every shell start. Cheap noop if already
# correct; instantly restores a broken link or replaces a stray regular file.
() {
  local src="$HOME/dotfiles/.config/zellij/permissions.kdl"
  local dst="$HOME/.cache/zellij/permissions.kdl"
  [[ -f "$src" ]] || return
  if [[ "$(readlink -- "$dst" 2>/dev/null)" != "$src" ]]; then
    mkdir -p "${dst:h}"
    ln -sfn "$src" "$dst"
  fi
}

# Zellij wrapper: when invoked with no args (and not already inside a zellij
# session), attach to the most recently used session. Falls back to a fresh
# session if none exist. Any explicit args are passed through unchanged.
if command -v zellij >/dev/null 2>&1; then
  zellij() {
    if [[ -n "$ZELLIJ" ]] || (( $# > 0 )); then
      command zellij "$@"
      return
    fi

    # `list-sessions -sn` => short, no formatting. Sessions are listed
    # most-recently-active first; pick the first non-EXITED one.
    local line name last=""
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      [[ "$line" == *EXITED* ]] && continue
      name="${line%% *}"
      last="$name"
      break
    done < <(command zellij list-sessions -sn 2>/dev/null)

    if [[ -n "$last" ]]; then
      command zellij attach "$last"
    else
      command zellij
    fi
  }
fi

# Zellij integration: rename the current tab to <firstLetterUser>@<host>
# whenever we run `ssh <host>` (or our aliases `s` / `i` which expand to
# ssh / ish). Resets the tab name to the cwd basename after the command
# exits. Only active inside a zellij session.

if [[ -n "$ZELLIJ" ]] && command -v zellij >/dev/null 2>&1; then
  autoload -U add-zsh-hook

  _zj_rename_on_ssh() {
    # $1 is the command line as typed (before alias/function expansion).
    # Match ssh, ish, and the short aliases s / i.
    case "$1" in
      ssh\ *|ish\ *|s\ *|i\ *) ;;
      *) return ;;
    esac

    # Split the command into words and drop the leading command token.
    local -a words
    words=(${=1})
    (( ${#words} >= 2 )) || return
    words=("${words[@]:1}")

    # Walk arguments; skip flags (and their arg when relevant) until we
    # hit the first positional — that's the destination host.
    local w target=""
    local i=1
    while (( i <= ${#words} )); do
      w="${words[$i]}"
      case "$w" in
        -b|-c|-D|-E|-e|-F|-I|-i|-J|-L|-l|-m|-O|-o|-p|-Q|-R|-S|-W|-w)
          (( i += 2 ))
          ;;
        -*)
          (( i++ ))
          ;;
        *)
          target="$w"
          break
          ;;
      esac
    done
    [[ -z "$target" ]] && return

    local user host
    if [[ "$target" == *@* ]]; then
      user="${target%%@*}"
      host="${target#*@}"
    else
      user="$USER"
      host="$target"
    fi
    zellij action rename-tab "${user[1]}@${host}" >/dev/null 2>&1
    typeset -g _zj_in_ssh=1
  }

  _zj_reset_after_ssh() {
    [[ -z "$_zj_in_ssh" ]] && return
    zellij action rename-tab "${PWD:t}" >/dev/null 2>&1
    unset _zj_in_ssh
  }

  add-zsh-hook preexec _zj_rename_on_ssh
  add-zsh-hook precmd  _zj_reset_after_ssh
fi
