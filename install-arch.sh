#!/bin/bash

#Installing JDK21
sudo pacman -S -Y jdk21-openjdk maven tmux hugo ghostty tmux neovim

#Setting up env variables
#echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))" >>~/.bashrc
echo "export JAVA_HOME=/usr/lib/jvm/java-21-openjdk" >>~/.bashrc
echo "export ANDROID_HOME='$HOME/Android/Sdk'" >>~/.bashrc
echo "export PATH=$PATH:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/emulator" >>~/.zshrc

git clone git@github.com:omarortega87/nvim-ide.git

mkdir ~/.config/nvim
mkdir ~/.config/tmux

ln -s ~/.dotfiles/nvim-ide/* ~/.config/nvim
ln -s ~/.dotfiles/tmux/* ~/.config/tmux

## installing nvm and node lts

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

source .bashrc

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

cd ..

git clone git@github.com:omarortega87/dev-notes.git

