#!/bin/bash

#Installing VIM from source code and with python
sudo apt install libncurses5-dev \
    libgtk2.0-dev libatk1.0-dev \
    libcairo2-dev python-dev \
    python3-dev git

sudo apt remove vim vim-runtime gvim

cd /usr && sudo git clone https://github.com/vim/vim.git && cd vim  

cd vim

sudo ./configure --with-features=huge \
    --enable-multibyte \
    --enable-pythoninterp=yes \
    --enable-python3interp=yes \
    --enable-gui=gtk2 \
    --enable-cscope \ 
    --prefix=/usr/local/

make

sudo make install

sudo update-alternatives --install /usr/bin/editor editor /usr/local/bin/vim 1
sudo update-alternatives --set editor /usr/local/bin/vim
sudo update-alternatives --install /usr/bin/vi vi /usr/local/bin/vim 1
sudo update-alternatives --set vi /usr/local/bin/vim  

vim --version | grep python

# Get dotfiles installation directory

cd ~/.dotfiles
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ~
ln -sf "$DOTFILES_DIR/.zshrc" ~
ln -sf "$DOTFILES_DIR/.vimrc" ~
ln -sf "$DOTFILES_DIR/.tmux.conf" ~

cd

curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install --lts

sudo apt-get update && sudo apt-get upgrade

sudo apt-get install openjdk-11-jdk

export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
export PATH=$PATH:$JAVA_HOME/bin

sudo apt update

sudo apt install maven

sudo apt install neovim

sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
           https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    
mkdir ~/.config/nvim

cp ~/.dotfiles/.vimrc ~/.config/nvim/init.vim

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

nvm install --lts

cd mkdir -p ~/Documents/githubprojects

cd ~/Documents/githubprojects/

git clone https://github.com/omarortega87/mobile-browser-framework.git



