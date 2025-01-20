#!/bin/bash

#Installing VIM from source code and with python
sudo apt install -y libncurses5-dev \
	libgtk2.0-dev libatk1.0-dev \
	libcairo2-dev  \
	python3-dev git curl

sudo snap install nvim --classic

sudo snap install alacritty --classic

sudo apt-get install build-essential

sudo apt-get update && sudo apt-get upgrade

sudo apt-get install -y openjdk-21-jdk

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))" >>~/.bashrc
echo "export ANDROID_HOME='/home/omarortega/Android/Sdk'" >>~/.bashrc
echo "export PATH=$PATH:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/emulator" >>~/.bashrc

source ~/.bashrc

curl -fsSL https://get.docker.com -o install-docker.sh

sudo sh install-docker.sh

sudo apt update

sudo apt install -y maven

sudo apt install -y tmux

## Alacritty setup

cd ~

cd .config

mkdir alacritty

mkdir nvim

ln -s ~/.dotfiles/alacritty ~/.config
ln -s ~/.dotifles/nvim ~/.config

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

