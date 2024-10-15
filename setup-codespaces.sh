#!/bin/sh

set -eux

if [ -z "$USER" ]; then
  USER=$(id -un)
fi

mv /workspaces/.codespaces/.persistedshare/dotfiles $HOME/dotfiles

cd $HOME

# Make passwordless sudo work
export SUDO_ASKPASS=/bin/true

# Change shell to zsh
sudo chsh "$(id -un)" --shell "/usr/bin/zsh"

add-apt-repository ppa:neovim-ppa/stable
apt-get update
apt-get install neovim

stow nvim ruby zsh
