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
    sudo rm -f -r /Library/Caches/Homebrew/*
    #source lib/osx.sh
    
    sudo gem install wbench
    sudo gem install neovim
    sudo easy_install pip
    pip install --user neovim
    pip3 install --user neovim
    
    # add term colors
    cat <<EOF|tic -x -
tmux-256color|tmux with 256 colors,
  ritm=\E[23m, rmso=\E[27m, sitm=\E[3m, smso=\E[7m,
  use=xterm-256color, use=screen-256color,
EOF

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
    
    #install pre-requiste
    sudo yum -y install epel-release
    sudo curl -o /etc/yum.repos.d/dperson-neovim-epel-7.repo https://copr.fedorainfracloud.org/coprs/dperson/neovim/repo/epel-7/dperson-neovim-epel-7.repo 
    sudo yum -y install wget docker-io tree bash-completion bash-completion-extras jq neovim xorg-x11-xauth python-pip xclip ncurses-term ack the_silver_searcher
    sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm
    sudo yum -y install python35u python35u-pip
    sudo pip install --upgrade pip
    sudo pip install neovim
    sudo pip3.5 install neovim
    
    sudo chkconfig docker on
    sudo service docker start
    if [ ! -n "$(command -v tmux)" ]; then sudo bash tmux/install.sh; fi
    
    # add term colors
    cat <<EOF|tic -x -
tmux|tmux terminal multiplexer,
  ritm=\E[23m, rmso=\E[27m, sitm=\E[3m, smso=\E[7m, Ms@,
  use=xterm+tmux, use=screen,

tmux-256color|tmux with 256 colors,
  use=xterm-256color, use=tmux,
EOF

fi

tic resources/xterm-256color-italic.terminfo
tic resources/tmux-256color-italic.terminfo

curl https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh > ~/.bash-preexec.sh
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh > ~/.git-prompt.sh
sudo bash -c "curl https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/diff-so-fancy > /usr/local/bin/diff-so-fancy"
sudo bash -c "curl https://raw.githubusercontent.com/git/git/master/contrib/diff-highlight/diff-highlight > /usr/local/bin/diff-highlight"
sudo chmod +x /usr/local/bin/diff-so-fancy
sudo chmod +x /usr/local/bin/diff-highlight

mkdir -p ~/.local/share/fonts
pushd ~/.local/share/fonts && curl -fLo "Firacode Retina Nerd Font Complete Mono.otf" https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/FiraCode/Retina/complete/Fura%20Code%20Retina%20Nerd%20Font%20Complete%20Mono.otf && popd
pushd ~/.local/share/fonts && curl -fLo "Droid Sans Mono Nerd Font Complete Mono.otf" https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20for%20Powerline%20Nerd%20Font%20Complete%20Mono.otf && popd

# create symlinks
source lib/link.sh

#install vim plugins
nvim +PlugInstall +qall +silent
nvim +UpdateRemotePlugins +qall +silent

#local overrides
touch ~/.vimrc.local
touch ~/.bash_profile.local
touch ~/.dotfilesrc

#install tmux plugins
# start a server but don't attach to it
/usr/local/bin/tmux start-server
# create a new session but don't attach to it either
/usr/local/bin/tmux new-session -d
# install the plugins
bash ~/.tmux/plugins/tpm/scripts/install_plugins.sh
# killing the server is not required, I guess
/usr/local/bin/tmux kill-server

