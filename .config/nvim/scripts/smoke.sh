#!/run/current-system/sw/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd)
XDG_CONFIG_HOME="$REPO_ROOT/.config"
XDG_DATA_HOME="$REPO_ROOT/.local/share"
XDG_STATE_HOME="$REPO_ROOT/.local/state"
XDG_CACHE_HOME="$REPO_ROOT/.cache"

export XDG_CONFIG_HOME
export XDG_DATA_HOME
export XDG_STATE_HOME
export XDG_CACHE_HOME

mkdir -p "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

nvim --headless +qa
nvim --headless "+Lazy! sync" +qa
nvim --headless "+lua assert(require('lazy'))" "+lua assert(require('telescope'))" "+lua assert(require('codecompanion'))" "+lua assert(type(vim.g.colors_name) == 'string' and vim.g.colors_name:match('^noctis'), 'expected noctis colorscheme')" +qa
