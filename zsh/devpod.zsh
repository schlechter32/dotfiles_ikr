# devpod zsh completion
# Must be sourced AFTER compinit

_devpod_workspaces() {
  local -a workspaces
  workspaces=(${(f)"$(devpod list --output json 2>/dev/null | jq -r '.[].id')"})
  compadd -a workspaces
}

_devpod() {
  local state

  _arguments \
    '1: :->cmd' \
    '*: :->args'

  case $state in
    cmd)
      local -a cmds
      cmds=(
        'up:start or create a workspace'
        'stop:stop a running workspace'
        'delete:delete a workspace'
        'ssh:ssh into a workspace'
        'list:list all workspaces'
        'status:show workspace status'
        'provider:manage providers'
        'ide:manage IDEs'
        'context:manage contexts'
        'version:print version'
      )
      _describe 'command' cmds
      ;;
    args)
      case $words[2] in
        stop|delete|ssh|status)
          _devpod_workspaces
          ;;
        up)
          _alternative \
            'workspaces:workspace:_devpod_workspaces' \
            'dirs:directory:_files -/'
          ;;
      esac
      ;;
  esac
}

compdef _devpod devpod
