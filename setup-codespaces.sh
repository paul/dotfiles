#!/bin/sh

set -eux

if [ ! -d $HOME/dotfiles ]; then
  mv /workspaces/.codespaces/.persistedshare/dotfiles $HOME/dotfiles
fi

cd $HOME

# Make passwordless sudo work
export SUDO_ASKPASS=/bin/true

# Apt shouldn't ask any questions
export DEBIAN_FRONTEND=noninteractive

# Change shell to zsh
sudo chsh "$(id -un)" --shell "/usr/bin/zsh"

# Install useful packages
sudo -E apt-get update
sudo -E apt-get install -y tree libfuse2 stow

# Install neovim
# Ubuntu is the worst
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -s /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

# Eza (better ls)
wget -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz
sudo install -vD -m 775 eza /usr/local/bin
rm eza

# Hub CLI
wget -c https://github.com/mislav/hub/releases/download/v2.14.2/hub-linux-amd64-2.14.2.tgz -O - | tar xz
sudo ./hub-linux-amd64-2.14.2/install
rm -rf hub-linux-amd64-2.14.2

# zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# direnv
curl -sfL https://direnv.net/install.sh | bash

# lazydocker
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

cd dotfiles

stow nvim ruby # zsh git

# Setup zsh
# Install starship
curl -sS https://starship.rs/install.sh -o install-starship.sh
sh install-starship.sh -y
rm install-starship.sh

# Setup Neovim
# Install lazyvim plugins
/usr/local/bin/nvim --headless -c 'luafile install-lazynvim.lua' -c 'qall'

# Setup Direnv
cd /workspaces/${RepositoryName}
direnv allow
