#!/bin/bash

#Installing VIM from source code and with python
sudo apt install -y git curl zsh
chsh -s $(which zsh)
# Oh My ZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#Installing neovim
sudo snap install nvim --classic
#Installing alacritty
sudo snap install alacritty --classic
#Installing build essential
sudo apt-get install -y build-essential
# Upgrading
sudo apt-get update && sudo apt-get -y upgrade
#Installing JDK21
sudo apt-get install -y openjdk-21-jdk
#Setting up env variables
echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))" >>~/.zshrc
echo "export ANDROID_HOME='$HOME/Android/Sdk'" >>~/.zshrc
echo "export PATH=$PATH:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/emulator" >>~/.zshrc

source ~/.zshrc
#Installing docker
curl -fsSL https://get.docker.com -o install-docker.sh

sudo sh install-docker.sh

sudo apt update
#Installing Maven
sudo apt install -y maven
#Installing tmux
sudo apt install -y tmux

## Alacritty setup

cd ~

cd .config

mkdir alacritty

mkdir nvim

ln -s ~/.dotfiles/nvim-ide/* ~/.config/nvim
ln -s ~/.dotfiles/tmux/.tmux.conf ~/

ln -s ~/.dotfiles/alacritty/alacritty.toml ~/.config

## installing nvm and node lts

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

source .zshrc

nvm install --lts

## installing appium

npm install -g appium

appium driver install uiautomator2

mkdir -p ~/Documents/dev-projects

cd ~/Documents/dev-projects

git clone git@github.com:omarortega87/java-training.git

git clone git@github.com:omarortega87/wdio-appium.git

git clone git@github.com:omarortega87/wdio-training.git

git clone git@github.com:omarortega87/selenium-appium.git

