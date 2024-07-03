#!/bin/bash

#Installing VIM from source code and with python
sudo apt install -y libncurses5-dev \
	libgtk2.0-dev libatk1.0-dev \
	libcairo2-dev python-dev \
	python3-dev git curl

sudo snap install nvim --classic

sudo apt-get install build-essential

sudo apt-get update && sudo apt-get upgrade

sudo apt-get install -y openjdk-17-jdk

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))" >>~/.bashrc
echo "export ANDROID_HOME='/home/omarortega/Android/Sdk'" >>~/.bashrc
echo "export PATH=$PATH:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/emulator" >>~/.bashrc

source ~/.bashrc

curl -fsSL https://get.docker.com -o install-docker.sh

sudo sh install-docker.sh

sudo apt update

sudo apt install -y maven

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

source ~/.bashrc

nvm install --lts

npm install -g appium-installer

sudo apt install -y tmux

cd ~/.config

git clone git@github.com:omarortega87/nvim.git

sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

## Alacritty setup

ln -s ~/.dotfiles/alacritty.toml ~/.config/alacritty/alacritty.toml
ln -s ~/.dotfiles/catppuccin-mocha.toml ~/.config/alacritty/catpuccin-mocha.toml

ln -s ~/.dotfiles/tmux/.tmux.conf ~/.tmux.conf

ln -s ~/.dotifles/nvim ~/.confi/nvim

mkdir -p ~/Documents/dev-projects

cd ~/Documents/dev-projects

git clone git@github.com:omarortega87/selenoid-appium-grid.git

git clone git@github.com:omarortega87/webdriver-automation-universe.git

git clone git@github.com:omarortega87/wdio.git

git clone git@github.com:omarortega87/java-training.git

git clone git@github.com:omarortega87/wdio-appium.git

git clone git@github.com:omarortega87/wdio-training.git

git clone git@github.com:omarortega87/selenium-appium.git

git clone git@github.com:omarortega87/appium-selenoid.git

git clone git@github.com:omarortega87/selenoid-appium-grid.git

