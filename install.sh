#!/bin/bash

#Installing VIM from source code and with python
sudo apt install libncurses5-dev \
    libgtk2.0-dev libatk1.0-dev \
    libcairo2-dev python-dev \
    python3-dev git

sudo apt remove vim vim-runtime gvim

sudo apt-get update && sudo apt-get upgrade

sudo apt-get install openjdk-17-jdk

export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
export PATH=$PATH:$JAVA_HOME/bin

sudo apt update

sudo apt install maven

sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
           https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    
mkdir ~/.config/nvim

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

nvm install --lts

mkdir -p ~/Documents/githubprojects


