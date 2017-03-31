#!/usr/bin/env bash

command_exists() {
    type "$1" > /dev/null 2>&1
}

echo "Installing dotfiles."

echo "Initializing submodule(s)"
git submodule update --init --recursive

# only perform macOS-specific install
if [ "$(uname)" == "Darwin" ]; then
    echo -e "\n\nRunning on OSX"

    source install/brew.sh
    source install/osx.sh

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
    
    #install pre-requiste
    yum -y install epel-release
    curl -o /etc/yum.repos.d/dperson-neovim-epel-7.repo https://copr.fedorainfracloud.org/coprs/dperson/neovim/repo/epel-7/dperson-neovim-epel-7.repo 
    yum -y install docker-io vim tmux zsh bash-completion bash-completion-extras jq neovim
    service docker restart
    chkconfig docker on
fi

cd ~
git clone https://github.com/magicmonty/bash-git-prompt.git .bash-git-prompt --depth=1
wget https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh

source install/link.sh

echo "Done. Reload your terminal."
