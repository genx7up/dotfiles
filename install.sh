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

    source lib/brew.sh
    source lib/osx.sh

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
    
    #install pre-requiste
    sudo yum -y install epel-release
    sudo curl -o /etc/yum.repos.d/dperson-neovim-epel-7.repo https://copr.fedorainfracloud.org/coprs/dperson/neovim/repo/epel-7/dperson-neovim-epel-7.repo 
    sudo yum -y install docker-io vim tmux zsh bash-completion bash-completion-extras jq neovim
    sudo chkconfig docker on
    sudo service docker start
fi

cd ~
curl https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh > .bash-preexec.sh
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh > .git-prompt.sh

source .dotfiles/lib/link.sh

echo "Done. Reload your terminal."
