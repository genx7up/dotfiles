#!/usr/bin/env bash

#set -xe

command_exists() {
    type "$1" > /dev/null 2>&1
}

TF_VER=0.11.14
PACKER_VER=1.4.1
DRONE_VER=1.1.1
COMPOSE_VER=1.22.0
HUB_VER=2.12.1

echo "Installing dotfiles."

echo "Initializing submodule(s)"
git submodule update --init --recursive

# only perform macOS-specific install
if [ "$(uname)" == "Darwin" ]; then
    echo -e "\\n\\nRunning on OSX"

    source lib/brew.sh
    sudo rm -f -r /Library/Caches/Homebrew/*
    #source lib/osx.sh

    sudo gem install wbench
    sudo gem install neovim
    sudo easy_install pip
    pip install --user neovim pre-commit ruamel.yaml runlike awscli
    pip3 install --user neovim
    pip3 install --user --upgrade neovim
    npm install --global prettier bash-language-server eslint

    # add term colors
    tic resources/tmux-256color.terminfo

    # terraform
    if [[ ! -f "/usr/local/bin/terraform" ]]; then
        wget https://releases.hashicorp.com/terraform/$TF_VER/terraform_${TF_VER}_darwin_amd64.zip
        unzip terraform_${TF_VER}_darwin_amd64.zip -d /usr/local/bin/
        rm -rf terraform_${TF_VER}_darwin_amd64.zip
    fi

    # packer
    if [[ ! -f "/usr/local/bin/packer" ]]; then
        wget https://releases.hashicorp.com/packer/$PACKER_VER/packer_${PACKER_VER}_darwin_amd64.zip
        unzip packer_${PACKER_VER}_darwin_amd64.zip -d /usr/local/bin/
        rm -rf packer_${PACKER_VER}_darwin_amd64.zip
    fi

    #Drone
    if [[ ! -f "/usr/local/bin/drone" ]]; then
      pushd drone
      curl -L https://github.com/drone/drone-cli/releases/download/v${DRONE_VER}/drone_darwin_amd64.tar.gz | tar zx
      sudo cp drone /usr/local/bin
      rm -rf drone
      popd
    fi

    # Container diff tool
    curl -LO https://storage.googleapis.com/container-diff/latest/container-diff-darwin-amd64 && chmod +x container-diff-darwin-amd64 && sudo mv container-diff-darwin-amd64 /usr/local/bin/codiff

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform

    #install pre-requiste
    sudo yum -y install epel-release
    sudo yum -y install gcc-c++ wget unzip tree bash-completion bash-completion-extras jq xorg-x11-xauth python-pip xclip ncurses-term ack the_silver_searcher tcpdump bind-utils crudini yamllint ShellCheck bzip2
    sudo yum -y install gcc kernel-devel make ncurses-devel
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    sudo curl -sL https://rpm.nodesource.com/setup_14.x | sudo bash -
    sudo yum install -y nodejs
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce
    
    if [ "$(rpm --eval '%{centos_ver}')" == "7" ]; then
        sudo yum -y install https://repo.ius.io/ius-release-el7.rpm || :
        sudo yum -y install python36u python36u-pip python36u-devel
        
        # Install latest gcc
        sudo yum -y install centos-release-scl-rh
        sudo yum -y install devtoolset-11-gcc-c++
        export PATH=/opt/rh/devtoolset-11/root/bin/:$PATH

        #Install neovim from snap store
        sudo yum -y install snapd
        sudo systemctl enable --now snapd.socket
        sudo ln -fs /var/lib/snapd/snap /snap
        sudo systemctl restart snapd
        # sudo snap install nvim --classic
        wget -L https://github.com/neovim/neovim/releases/download/v0.7.2/nvim.appimage -O /usr/local/bin/nvim
        chmod +x /usr/local/bin/nvim
        
        sudo pip install --upgrade 'pip<21'
        sudo pip install neovim pre-commit ruamel.yaml runlike awscli
    else
        sudo yum -y install python3 python3-pip python3-devel
    fi
    
    sudo pip3 install neovim
    sudo pip3 install --upgrade neovim
    sudo npm install --global prettier bash-language-server eslint neovim

    sudo chkconfig docker on
    sudo service docker start
    if [ ! -n "$(command -v tmux)" ]; then sudo bash tmux/install.sh; fi
    if [ ! -n "$(command -v salt-call)" ]; then sudo bash salt/install.sh; fi

    # add term colors
    cat <<EOF|tic -x -
tmux|tmux terminal multiplexer,
  ritm=\E[23m, rmso=\E[27m, sitm=\E[3m, smso=\E[7m, Ms@,
  use=xterm+tmux, use=screen,

tmux-256color|tmux with 256 colors,
  use=xterm-256color, use=tmux,
EOF

    #docker-compose
    if [[ ! -f "/usr/local/bin/docker-compose" ]]; then
      sudo curl -L https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
      sudo chmod +x /usr/local/bin/docker-compose
    fi

    # terraform
    if [[ ! -f "/usr/local/bin/terraform" ]]; then
        wget https://releases.hashicorp.com/terraform/$TF_VER/terraform_${TF_VER}_linux_amd64.zip
        sudo unzip terraform_${TF_VER}_linux_amd64.zip -d /usr/local/bin/
        rm -rf terraform_${TF_VER}_linux_amd64.zip
    fi

    # packer
    if [[ ! -f "/usr/local/bin/packer" ]]; then
        wget https://releases.hashicorp.com/packer/$PACKER_VER/packer_${PACKER_VER}_linux_amd64.zip
        sudo unzip packer_${PACKER_VER}_linux_amd64.zip -d /usr/local/bin/
        rm -rf packer_${PACKER_VER}_linux_amd64.zip
        
        # Remove conflicting link
        unlink /usr/sbin/packer
    fi

    #Drone
    if [[ ! -f "/usr/local/bin/drone" ]]; then

      pushd drone
      curl -L https://github.com/drone/drone-cli/releases/download/v${DRONE_VER}/drone_linux_amd64.tar.gz | tar zx
      sudo install -t /usr/local/bin drone
      rm -rf drone
      popd

      # drop permissions for docker
      crudini --set /etc/sysconfig/selinux '' SELINUX permissive
      setenforce permissive
    fi

    # Container diff tool
    curl -LO https://storage.googleapis.com/container-diff/latest/container-diff-linux-amd64 && chmod +x container-diff-linux-amd64 && sudo mv container-diff-linux-amd64 /usr/local/bin/codiff
    
    # Hub tool
    if [[ ! -f "/usr/local/bin/hub" ]]; then
      curl -LO https://github.com/github/hub/releases/download/v${HUB_VER}/hub-linux-amd64-${HUB_VER}.tgz
      tar xvf hub-linux-amd64-${HUB_VER}.tgz && cd hub-linux-amd64-${HUB_VER}
      \cp -f bin/hub /usr/local/bin/hub
      \cp -f etc/hub.bash_completion.sh ~/.hub.bash_completion.sh
      \cp -rf share/vim/vimfiles/* ~/.dotfiles/config/nvim/
      cd .. && rm -rf hub-linux-amd64-${HUB_VER}*
      sudo chmod +x /usr/local/bin/hub
    fi

fi

# Auto-clean docker images
crontab -l | { cat; echo "0 * * * * /usr/bin/docker system prune -f"; } | crontab -
crontab -l | { cat; echo "0 0 * * * /usr/bin/docker system prune -af"; } | crontab -

tic resources/xterm-256color-italic.terminfo
tic resources/tmux-256color-italic.terminfo

curl https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh > ~/.bash-preexec.sh
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh > ~/.git-prompt.sh
sudo mkdir -p /usr/local/bin/lib
sudo bash -c "curl https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/diff-so-fancy > /usr/local/bin/diff-so-fancy"
sudo bash -c "curl https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/lib/DiffHighlight.pm > /usr/local/bin/lib/DiffHighlight.pm"
sudo chmod +x /usr/local/bin/diff-so-fancy

mkdir -p ~/.local/share/fonts
pushd ~/.local/share/fonts && curl -fLo "Firacode Retina Nerd Font Complete Mono.otf" https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/FiraCode/Retina/complete/Fira%20Code%20Retina%20Nerd%20Font%20Complete%20Mono.ttf && popd
pushd ~/.local/share/fonts && curl -fLo "Droid Sans Mono Nerd Font Complete Mono.otf" https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete%20Mono.otf && popd

# Drone docker files
cp -R drone /etc/
SECRET=`openssl rand -hex 32`
crudini --set /etc/drone/agent.env '' DRONE_SECRET $SECRET
crudini --set /etc/drone/server.env '' DRONE_SECRET $SECRET

# create symlinks
cd ~/.dotfiles
source lib/link.sh

#install vim plugins
export XDG_CONFIG_HOME=/root/.config
sed -i 's/^colorscheme tender$/" \0/' config/nvim/init.vim
#/snap/bin/nvim +PlugInstall +qall
nvim +PlugInstall +qall
git checkout -- config/nvim/init.vim
#/snap/bin/nvim +UpdateRemotePlugins +qall
nvim +UpdateRemotePlugins +qall

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
