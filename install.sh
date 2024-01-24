#!/bin/bash

#Installing VIM from source code and with python
sudo apt install libncurses5-dev \
	libgtk2.0-dev libatk1.0-dev \
	libcairo2-dev python-dev \
	python3-dev git

sudo apt-get update && sudo apt-get upgrade

sudo apt-get install openjdk-17-jdk

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))" >>~/.zshrc
echo "export ANDROID_HOME='/home/omarortega/Android/Sdk'" >>~/.zshrc
echo "export PATH=$PATH:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/emulator" >>~/.zshrc

source ~/.zshrc

sudo apt update

sudo apt install maven

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

source ~/.zshrc

nvm install --lts

npm install -g appium-installer

sudo apt install tmux

mkdir -p ~/Documents/dev-projects

cd ~/Documents/dev-projects

git clone git@github.com:omarortega87/selenoid-appium-grid.git

git clone git@github.com:omarortega87/webdriver-automation-universe.git

git clone git@github.com:omarortega87/wdio.git

git clone git@github.com:omarortega87/java-training.git

cd ~/.config

git clone git@github.com:omarortega87/nvim.git
