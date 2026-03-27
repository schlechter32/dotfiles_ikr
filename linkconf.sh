#! /bin/bash
set -euo pipefail

REPODIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p ~/.config/nvim
mkdir -p ~/.config/tmux
mkdir -p ~/.config/zellij
mkdir -p ~/.config/wezterm
mkdir -p ~/.config/ghostty
mkdir -p ~/.config/alacritty
mkdir -p ~/.config/btop
mkdir -p ~/.config/television
mkdir -p ~/.config/ptpython/
mkdir -p ~/.ipython/profile_default/
mkdir -p ~/.local/share/fonts/
mkdir -p ~/.gnupg
mkdir -p ~/.julia/config
mkdir -p ~/.julia/environments

# nvim conf
ln -sf $REPODIR/.config/nvim/* ~/.config/nvim
ln -sf $REPODIR/zsh ~/zsh
# tmux conf
ln -sf $REPODIR/.config/tmux/* ~/.config/tmux
ln -sf $REPODIR/.ipython/ipython_config.py ~/.ipython/profile_default/ipython_config.py
ln -sf $REPODIR/.config/ptpython/* ~/.config/ptpython/
ln -sf $REPODIR/.config/zellij/* ~/.config/zellij
ln -sf $REPODIR/.config/television/* ~/.config/television/
ln -sf $REPODIR/.config/wezterm/* ~/.config/wezterm
ln -sf $REPODIR/.config/ghostty/* ~/.config/ghostty
ln -sf $REPODIR/.config/alacritty/* ~/.config/alacritty
ln -sf $REPODIR/.config/btop/* ~/.config/btop
ln -sf $REPODIR/.config/starship.toml ~/.config/
ln -sf $REPODIR/.julia/config/startup.jl ~/.julia/config/startup.jl
ln -sf $REPODIR/.julia/environments/* ~/.julia/environments/
ln -sf $REPODIR/.zshrc $HOME
ln -sf $REPODIR/.latexmkrc $HOME
ln -sf $REPODIR/nbin/ $HOME
ln -sf $REPODIR/.local/share/fonts/* ~/.local/share/fonts
ln -sf $REPODIR/.gitconfig $HOME
ln -sf $REPODIR/.gnupg/gpg-agent.conf $HOME/.gnupg
mkdir -p ~/.ssh
cp -f "$REPODIR/.ssh/config" "$HOME/.ssh/config"

if command -v nix &>/dev/null && nix --version &>/dev/null; then
    echo "On nix assuming shelltools already installed"
else
    if [ $(uname) == "Darwin" ]; then
        echo "On Darwin"

    else

        if [[ $(hostname) == *"cnode"* ]]; then
            ln -sf $REPODIR/.gitconfigikr $HOME/.gitconfig
        elif [[ $(hostname) == *"pc"* ]]; then

            ln -sf $REPODIR/.gitconfigikr $HOME/.gitconfig
        fi
    fi
fi
