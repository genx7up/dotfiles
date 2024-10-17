#!/usr/bin/env bash

# This script sets up a development environment across different Unix-like operating systems
# It installs and configures various tools and utilities for software development

set -xe  # Uncomment to enable debugging

# Function to check if a command exists
command_exists() {
    type "$1" > /dev/null 2>&1
}

# Version variables for various tools
TF_VER=1.7.3
PACKER_VER=1.10.1
DRONE_VER=1.1.1
COMPOSE_VER=v2.24.5
HUB_VER=2.14.2  # Note: Consider replacing with GitHub CLI (gh) as Hub is no longer maintained

echo "Installing dotfiles."

echo "Initializing submodule(s)"
git submodule update --init --recursive

# OS-specific installation
if [ "$(uname)" == "Darwin" ]; then
    echo -e "\\n\\nRunning on macOS"

    # Install Homebrew and packages
    source lib/brew.sh

    # Clean up Homebrew cache
    sudo rm -rf /Library/Caches/Homebrew/*

    # Uncomment to run macOS-specific setup
    #source lib/osx.sh

    # Install Ruby gems
    echo "Installing Ruby gems..."
    sudo gem install wbench neovim ruby-beautify starscope seeing_is_believing rubocop haml_lint scss-lint mdl

    # Install Python packages
    echo "Installing Python packages..."
    pip3 install --user neovim pre-commit ruamel.yaml runlike awscli
    pip3 install --user --upgrade neovim
    pip3 install --user vim-vint==0.3.21 pip_search howdoi

    # Install global npm packages
    echo "Installing global npm packages..."
    npm install --global prettier bash-language-server eslint jsonlint tern flow-bin typescript js-beautify

    # Add terminal colors
    echo "Adding terminal colors..."
    tic resources/tmux-256color.terminfo

    # Install Terraform
    if [[ ! -f "/usr/local/bin/terraform" ]]; then
        echo "Installing Terraform..."
        wget https://releases.hashicorp.com/terraform/$TF_VER/terraform_${TF_VER}_darwin_amd64.zip
        unzip terraform_${TF_VER}_darwin_amd64.zip -d /usr/local/bin/
        rm -rf terraform_${TF_VER}_darwin_amd64.zip
    fi

    # Install Packer
    if [[ ! -f "/usr/local/bin/packer" ]]; then
        echo "Installing Packer..."
        wget https://releases.hashicorp.com/packer/$PACKER_VER/packer_${PACKER_VER}_darwin_amd64.zip
        unzip packer_${PACKER_VER}_darwin_amd64.zip -d /usr/local/bin/
        rm -rf packer_${PACKER_VER}_darwin_amd64.zip
    fi

    # Install Drone CLI
    if [[ ! -f "/usr/local/bin/drone" ]]; then
        echo "Installing Drone CLI..."
        pushd drone
        curl -L https://github.com/drone/drone-cli/releases/download/v${DRONE_VER}/drone_darwin_amd64.tar.gz | tar zx
        sudo cp drone /usr/local/bin
        rm -rf drone
        popd
    fi

    # Install Container diff tool
    echo "Installing Container diff tool..."
    curl -LO https://storage.googleapis.com/container-diff/latest/container-diff-darwin-amd64 && chmod +x container-diff-darwin-amd64 && sudo mv container-diff-darwin-amd64 /usr/local/bin/codiff

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Linux-specific setup

    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu setup
        echo -e "\\n\\nRunning on Debian"
        source lib/debian.sh

        # Install development tools and utilities
        sudo apt-get install -y wget unzip tree bash-completion jq x11-xauth xclip ncurses-term ack silversearcher-ag tcpdump dnsutils crudini yamllint shellcheck bzip2 elixir tidy

        # Install additional Python packages
        echo "Installing Python packages..."
        pip3 install --user neovim pre-commit ruamel.yaml runlike awscli
        pip3 install --user --upgrade neovim
        pip3 install --user vim-vint==0.3.21 pip_search howdoi

        # Install additional Ruby gems
        echo "Installing Ruby gems..."
        sudo gem install wbench neovim ruby-beautify starscope seeing_is_believing rubocop haml_lint scss-lint mdl

        # Install additional global npm packages
        echo "Installing additional global npm packages..."
        npm install --global prettier bash-language-server eslint jsonlint tern flow-bin typescript js-beautify

        # Install Docker
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io

        # Configure Docker
        sudo systemctl enable docker
        sudo systemctl start docker

        # Install tmux and salt if not present
        if ! command_exists tmux; then sudo bash tmux/install.sh; fi
        if ! command_exists salt-call; then sudo bash salt/install.sh; fi

    elif [ -f /etc/redhat-release ]; then
        # Red Hat/CentOS/Fedora setup
        echo -e "\\n\\nRunning on Red Hat / CentOS / Fedora"

        # Install prerequisites and development tools
        sudo yum -y install epel-release
        sudo yum -y install gcc-c++ wget unzip tree bash-completion bash-completion-extras jq xorg-x11-xauth \
            python3 python3-pip python3-devel xclip ncurses-term ack the_silver_searcher tcpdump bind-utils crudini yamllint ShellCheck \
            bzip2 gcc kernel-devel make ncurses-devel elixir tidy yum-utils device-mapper-persistent-data lvm2

        # Install Node.js
        sudo yum install https://rpm.nodesource.com/pub_16.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y
        sudo yum install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1

        # Install Ruby and gems
        sudo yum -y install ruby rubygems
        sudo gem install wbench ruby-beautify starscope seeing_is_believing rubocop haml_lint scss-lint mdl || :

        # Install Docker
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum -y install docker-ce docker-ce-cli containerd.io

        # Install GitHub CLI
        sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo yum install -y gh

        # CentOS 7 specific setup
        if [ "$(rpm --eval '%{centos_ver}')" == "7" ]; then
            # Install latest gcc
            sudo yum -y install centos-release-scl-rh
            sudo yum -y install devtoolset-11-gcc-c++
            echo "source /opt/rh/devtoolset-11/enable" >> ~/.bashrc
            source ~/.bashrc

            # Install Neovim
            sudo yum -y install snapd
            sudo systemctl enable --now snapd.socket
            sudo ln -fs /var/lib/snapd/snap /snap
            sudo systemctl restart snapd
            # sudo snap install nvim --classic
            wget -L https://github.com/neovim/neovim/releases/download/v0.7.2/nvim.appimage -O /usr/local/bin/nvim
            chmod +x /usr/local/bin/nvim

            # Install Python packages
            sudo pip install --upgrade 'pip<21'
            sudo pip install neovim pre-commit ruamel.yaml runlike awscli
        fi

        # Install Python packages
        sudo pip3 install --upgrade pip
        sudo pip3 install neovim pre-commit ruamel.yaml runlike awscli
        sudo pip3 install vim-vint==0.3.21 pip_search howdoi

        # Install global npm packages
        sudo npm install --global prettier bash-language-server eslint neovim jsonlint tern flow-bin typescript js-beautify

        # Configure Docker
        sudo systemctl enable docker
        sudo systemctl start docker

        # Install tmux and salt if not present
        if ! command_exists tmux; then sudo bash tmux/install.sh; fi
        if ! command_exists salt-call; then sudo bash salt/install.sh; fi

        # Configure SELinux for Docker
        sudo setenforce 0
        sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

    fi

    # Common Linux setup
    echo "Performing common Linux setup..."

    # Add terminal colors
    cat <<EOF|tic -x -
tmux|tmux terminal multiplexer,
  ritm=\E[23m, rmso=\E[27m, sitm=\E[3m, smso=\E[7m, Ms@,
  use=xterm+tmux, use=screen,

tmux-256color|tmux with 256 colors,
  use=xterm-256color, use=tmux,
EOF

    # Install Docker Compose
    if [[ ! -f "/usr/local/bin/docker-compose" ]]; then
        echo "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VER}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    # Install Terraform
    if [[ ! -f "/usr/local/bin/terraform" ]]; then
        echo "Installing Terraform..."
        wget "https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip"
        sudo unzip "terraform_${TF_VER}_linux_amd64.zip" -d /usr/local/bin/
        rm -rf "terraform_${TF_VER}_linux_amd64.zip"
    fi

    # Install Packer
    if [[ ! -f "/usr/local/bin/packer" ]]; then
        echo "Installing Packer..."
        wget "https://releases.hashicorp.com/packer/${PACKER_VER}/packer_${PACKER_VER}_linux_amd64.zip"
        sudo unzip "packer_${PACKER_VER}_linux_amd64.zip" -d /usr/local/bin/
        rm -rf "packer_${PACKER_VER}_linux_amd64.zip"
        # Remove conflicting link
        sudo unlink /usr/sbin/packer || true
    fi

    # Install Drone CLI
    if [[ ! -f "/usr/local/bin/drone" ]]; then
        echo "Installing Drone CLI..."
        pushd drone
        curl -L "https://github.com/drone/drone-cli/releases/download/v${DRONE_VER}/drone_linux_amd64.tar.gz" | tar zx
        sudo install -t /usr/local/bin drone
        rm -rf drone
        popd
    fi

    # Install Container diff tool
    echo "Installing Container diff tool..."
    curl -LO https://storage.googleapis.com/container-diff/latest/container-diff-linux-amd64 && chmod +x container-diff-linux-amd64 && sudo mv container-diff-linux-amd64 /usr/local/bin/codiff

    # Install Hub tool
    if [[ ! -f "/usr/local/bin/hub" ]]; then
        echo "Installing Hub tool..."
        curl -LO "https://github.com/github/hub/releases/download/v${HUB_VER}/hub-linux-amd64-${HUB_VER}.tgz"
        tar xvf "hub-linux-amd64-${HUB_VER}.tgz" && cd "hub-linux-amd64-${HUB_VER}"
        sudo cp -f bin/hub /usr/local/bin/hub
        cp -f etc/hub.bash_completion.sh ~/.hub.bash_completion.sh
        cp -rf share/vim/vimfiles/* ~/.dotfiles/config/nvim/
        cd .. && rm -rf "hub-linux-amd64-${HUB_VER}"*
        sudo chmod +x /usr/local/bin/hub
    fi

    # Install Minikube
    echo "Installing Minikube..."
    if command_exists dpkg; then
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
        sudo dpkg -i minikube_latest_amd64.deb
        rm minikube_latest_amd64.deb
    else
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
        sudo rpm -Uvh minikube-latest.x86_64.rpm
        rm minikube-latest.x86_64.rpm
    fi
    minikube start --force

fi

# Set up Docker auto-clean cron jobs
(crontab -l 2>/dev/null; echo "0 * * * * /usr/bin/docker system prune -f") | crontab -
(crontab -l 2>/dev/null; echo "0 0 * * * /usr/bin/docker system prune -af") | crontab -

# Install terminal color schemes
tic resources/xterm-256color-italic.terminfo
tic resources/tmux-256color-italic.terminfo

# Download and install various utility scripts
curl https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh > ~/.bash-preexec.sh
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh > ~/.git-prompt.sh
sudo mkdir -p /usr/local/bin/lib
sudo bash -c "curl https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/diff-so-fancy > /usr/local/bin/diff-so-fancy"
sudo bash -c "curl https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/lib/DiffHighlight.pm > /usr/local/bin/lib/DiffHighlight.pm"
sudo chmod +x /usr/local/bin/diff-so-fancy

# Install Nerd Fonts
mkdir -p ~/.local/share/fonts
pushd ~/.local/share/fonts && curl -fLo "Firacode Retina Nerd Font Complete Mono.otf" https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/FiraCode/Retina/complete/Fira%20Code%20Retina%20Nerd%20Font%20Complete%20Mono.ttf && popd
pushd ~/.local/share/fonts && curl -fLo "Droid Sans Mono Nerd Font Complete Mono.otf" https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete%20Mono.otf && popd

# Set up Drone configuration
cp -R drone /etc/
SECRET=`openssl rand -hex 32`
crudini --set /etc/drone/agent.env '' DRONE_SECRET $SECRET
crudini --set /etc/drone/server.env '' DRONE_SECRET $SECRET

# Create symlinks for dotfiles
cd ~/.dotfiles
source lib/link.sh

# Install Vim plugins
export XDG_CONFIG_HOME=/root/.config
sed -i 's/^colorscheme tender$/" \0/' config/nvim/init.vim
#/snap/bin/nvim +PlugInstall +qall
nvim +PlugInstall +qall
git checkout -- config/nvim/init.vim
#/snap/bin/nvim +UpdateRemotePlugins +qall
nvim +UpdateRemotePlugins +qall

# Create local override files
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

# Validate installations
echo "Validating installations..."

# Common tools across platforms
for tool in gcc python3 ruby node npm docker docker-compose gh nvim tmux terraform packer drone codiff hub minikube; do
    command_exists $tool && echo "$tool: OK" || echo "$tool: Not found"
done

# Check for Nerd Fonts
[ -d "$HOME/.local/share/fonts" ] && ls "$HOME/.local/share/fonts" | grep -q "Nerd Font" && echo "Nerd Fonts: OK" || echo "Nerd Fonts: Not found"

# Check for tmux plugins
[ -d "$HOME/.tmux/plugins" ] && [ "$(ls -A "$HOME/.tmux/plugins")" ] && echo "tmux plugins: OK" || echo "tmux plugins: Not found"

# Additional checks
for tool in wget unzip jq pip gem yamllint shellcheck; do
    command_exists $tool && echo "$tool: OK" || echo "$tool: Not found"
done

# Version checks for critical tools
docker --version
docker-compose --version
terraform --version
packer --version
nvim --version | head -n 1

echo "Validation complete. Please review the output for any missing or incorrectly installed software."
