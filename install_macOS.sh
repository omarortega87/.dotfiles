#!/bin/bash

#Install xcode command line tools
xcode-select --install

#Installing homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Git
brew install git

#install ghostty
brew install --cask ghostty

# Install JDK
brew install openjdk@21

#automatically symlink JDK
sudo ln -sfn $(brew --prefix)/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk

# Install neovim
brew install neovim

# Install maven
brew install maven

# Install gradle
brew install gradle

# Install pyenv
brew update
brew install pyenv

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init - zsh)"' >> ~/.zshrc

# Installing nvm

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash

# NVM Setup (needs sourcing to work in the same script)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 

source ~/.zshrc

# Installing node lts
nvm install --lts

## installing appium
npm install -g appium
appium driver install uiautomator2


# Environment Variables (using the recommended macOS tool)
echo "export JAVA_HOME=\$(/usr/libexec/java_home -v 21)" >> ~/.zshrc
echo "export ANDROID_HOME='$HOME/Android/Sdk'" >>~/.zshrc
echo "export PATH=$PATH:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/emulator" >>~/.zshrc

# Cloning nvim-ide
git clone https://github.com/omarortega87/nvim-ide.git

mkdir -p ~/.config/nvim

ln -sf ~/.dotfiles/nvim-ide/* ~/.config/nvim
ln -sf ~/.dotfiles/ghostty ~/.config
ln -sf ~/.dotfiles/tmux/ ~/.config



