BULK_HOME="/u/bulk/home/wima/$USER"
LAB_BULK_HOME="/bulk/netserv0/wimas/$USER"

export CPLEX_STUDIO_BINARIES="/ext/cplex/cplex/bin/x86-64_linux"
# export PATH="$HOME/.juliaup/bin/:$PATH"

export ST_PATH=/home/nclshrnk/source/simtree_wrapper
if [[ $(hostname) == *"node"* ]]; then

export JULIAUP_DEPOT_PATH="$BULK_HOME/.julia/"
export JULIA_DEPOT_PATH="$BULK_HOME/.julia/"
#
export PATH="$BULK_HOME/.juliaup/bin/:$PATH"
export PATH="$BULK_HOME/.julia/bin/:$PATH"

export ST_PATH=/u/home/wima/nclshrnk/source/simtree_wrapper

# export PATH="/u/bulk/home/wima/nclshrnk/julia/juliaup/julia-1.11.3/bin/:$PATH"
#
#
# export PATH="$BULK_HOME/.juliaup/bin/:$PATH"
# export PYENV_ROOT="$BULK_HOME/.pyenv"

# export JULIAUP_DEPOT_PATH="$HOME/.julia/"
# export JULIA_DEPOT_PATH="$HOME/.julia/"
# export JULIA_PKG_OFFLINE="true"
export CPLEX_STUDIO_BINARIES="/ext/cplex/cplex/bin/x86-64_linux"
# export ST_PATH=/u/home/wima/nclshrnk/source/SimTree_wrapper
# function st(){
#     source /u/home/wima/nclshrnk/source/SimTree_wrapper/st_wrapper.bash
# }

elif [[ $(hostname) == *"pc"* ]]; then

export ST_PATH=/home/nclshrnk/source/simtree_wrapper
export CPLEX_STUDIO_BINARIES="$HOME/ext/cplex/cplex/bin/x86-64_linux"
export PATH="$HOME/.juliaup/bin/:$PATH"
export PATH="$HOME/.julia/bin/:$PATH"
export ST_PATH=/u/home/wima/nclshrnk/source/simtree_wrapper
# function st(){
#     source /u/home/wima/nclshrnk/source/SimTree_wrapper/st_wrapper.bash
# }

elif command -v nix &>/dev/null && nix --version &>/dev/null; then
# export nethome=/bulk/netserv0/wimas/nclshrnk/
# export JULIAUP_DEPOT_PATH="$HOME/.julia/"
# export JULIA_DEPOT_PATH="$HOME/.julia/"
export JULIAUP_DEPOT_PATH="$LAB_BULK_HOME/.julia/"
export JULIA_DEPOT_PATH="$LAB_BULK_HOME/.julia/"
#
export PATH="$LAB_BULK_HOME/.juliaup/bin/:$PATH"
export PATH="$LAB_BULK_HOME/.julia/bin/:$PATH"
export PATH="$LAB_BULK_HOME/.julia/bin/:$PATH"
if [[ "${DOTFILES_INSTALL_MODE:-}" == "container" ]]; then
export UV_CACHE_DIR="${UV_CACHE_DIR:-$HOME/.cache/uv}"
else
export UV_CACHE_DIR="$LAB_BULK_HOME/.uv/cache"
fi
# elif [[ $(hostname) == *"cobra"* ]]; then

# export PATH="$HOME/.juliaup/bin/:$PATH"

# export JULIAUP_DEPOT_PATH="$LAB_BULK_HOME/.julia/"
# export JULIA_DEPOT_PATH="$LAB_BULK_HOME/.julia/"

export ST_PATH=$LAB_BULK_HOME/source/simtree_wrapper
# function st(){
#     source $HOME/source/simtree_wrapper/st_wrapper.bash
# }
else

export JULIAUP_DEPOT_PATH="$HOME/.julia/"
export JULIA_DEPOT_PATH="$HOME/.julia/"

export PATH="$HOME/.juliaup/bin/:$PATH"
export PATH="$HOME/.julia/bin/:$PATH"
fi

function st(){
    source $ST_PATH/st_uv_wrapper.bash
}
