#!/bin/bash

#Installing VIM from source code and with python
sudo dnf install -y git curl zsh
chsh -s $(which zsh)
# Oh My ZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#Installing neovim
sudo dnf install neovim
#Installing alacritty
sudo dnf install alacritty
#Installing FZF 
sudo dnf install fzf
# Upgrading
sudo dnf update && sudo upgrade
#Installing JDK21
#sudo dnf install -y openjdk-21-jdk
#Setting up env variables
echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))" >>~/.zshrc
echo "export ANDROID_HOME='$HOME/Android/Sdk'" >>~/.zshrc
echo "export PATH=$PATH:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/emulator" >>~/.zshrc

echo "alias sd='cd ~/Documents && cd \$(find * -type d | fzf)'" >> ~/.zshrc
source ~/.zshrc
#Installing docker
curl -fsSL https://get.docker.com -o install-docker.sh

sudo sh install-docker.sh

sudo dnf update
#Installing Maven
sudo dnf install maven
#Installing tmux
sudo dnf install -y tmux

## Alacritty setup

cd ~

cd .config

mkdir alacritty

mkdir nvim

cd ~/.dotfiles

snap install ghostty --classic

git clone git@github.com:omarortega87/nvim-ide.git

ln -s ~/.dotfiles/nvim-ide/* ~/.config/nvim
ln -s ~/.dotfiles/tmux ~/.config
ln -s ~/.dotfiles/ghostty ¬/.config
ln -s ~/.dotfiles/alacritty/ ~/.config

## installing nvm and node lts

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

source .zshrc

nvm install --lts

## installing appium

npm install -g appium

appium driver install uiautomator2

# Installing tmux plugings
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm


mkdir -p ~/Documents/dev-projects

cd ~/Documents/dev-projects

git clone git@github.com:omarortega87/java-training.git

git clone git@github.com:omarortega87/wdio-appium.git

git clone git@github.com:omarortega87/wdio-training.git

git clone git@github.com:omarortega87/selenium-appium.git

cd ~/.dotfiles
git clone git@github.com:omarortega87/vim.git

ln -s ~/.dotfiles/vim ~/.config/nvim



