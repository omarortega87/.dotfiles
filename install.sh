#!/bin/bash
#Installing git 
sudo apt-get install git

#Installing zsh
sudo apt-get install zsh

#Installing oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

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

#Installing zsh highlight
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting}
# Get dotfiles installation directory

cd ~/.dotfiles
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ~
ln -sf "$DOTFILES_DIR/.zshrc" ~
ln -sf "$DOTFILES_DIR/.vimrc" ~
ln -sf "$DOTFILES_DIR/.tmux.conf" ~
