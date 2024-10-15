#!/bin/sh

set -eux

if [ ! -d $HOME/dotfiles ]; then
  mv /workspaces/.codespaces/.persistedshare/dotfiles $HOME/dotfiles
fi

cd $HOME

# Make passwordless sudo work
export SUDO_ASKPASS=/bin/true

# Change shell to zsh
sudo chsh "$(id -un)" --shell "/usr/bin/zsh"

sudo apt-get update

# Install neovim
sudo apt-get install -y libfuse2
# Ubuntu is the worst
curl -L -o nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
install -D nvim.appimage $HOME/bin/nvim

cd dotfiles

stow nvim ruby zsh

# Setup Lazyvim
$HOME/bin/nvim --headless -c 'luafile install-lazynvim.lua' -c 'qall'
