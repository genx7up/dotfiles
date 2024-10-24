#!/usr/bin/env bash

# This script sets up a development environment across different Unix-like operating systems
# It installs and configures various tools and utilities for software development

set -e

# Enable debug mode if '--debug' is the last argument
[[ ${@: -1} == '--debug' ]] && set -x

# Version variables for various tools
TF_VER=1.7.3
PACKER_VER=1.10.1
DRONE_VER=1.1.1
DOCKER_COMPOSE_VER=2.24.6
HUB_VER=2.14.2  # Note: Consider replacing with GitHub CLI (gh) as Hub is no longer maintained

echo "Installing dotfiles."

echo "Initializing submodule(s)"
git submodule update --init --recursive

# Function to check if a command exists
command_exists() {
    type "$1" > /dev/null 2>&1
}

# Function to install a package using the appropriate package manager
install_package() {
    if ! command_exists "$1"; then
        if command_exists apt-get; then
            sudo apt-get install -y "$1"
        elif command_exists yum; then
            sudo yum install -y "$1"
        elif command_exists brew; then
            brew install "$1"
        else
            echo "Unable to install $1. No supported package manager found."
            return 1
        fi
    else
        echo "$1 already installed"
    fi
}

# Function to install a Python package
install_pip_package() {
    if ! pip3 list | grep -q "^$1 "; then
        pip3 install "$1"
    else
        echo "$1 already installed"
    fi
}

# Function to install a Ruby gem
install_gem() {
    if ! gem list | grep -q "^$1 "; then
        sudo gem install "$1"
    else
        echo "$1 already installed"
    fi
}

# Function to install a global npm package
install_npm_package() {
    if ! npm list -g "$1" > /dev/null 2>&1; then
        sudo npm install --global "$1"
    else
        echo "$1 already installed"
    fi
}

# Function to install a tool
install_tool() {
    local tool=$1
    local version=$2
    local install_command=$3
    
    if ! command_exists "$tool"; then
        echo "Installing $tool..."
        if [ "$(uname)" == "Darwin" ]; then
            brew install "$tool"
        else
            eval "$install_command"
        fi
    else
        echo "$tool already installed"
    fi
}

# OS-specific setup
if [ "$(uname)" == "Darwin" ]; then
    echo -e "\n\nRunning on macOS"
    source lib/brew.sh
    # Uncomment to run macOS-specific setup
    #source lib/osx.sh
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    if [ -f /etc/debian_version ]; then
        echo -e "\n\nRunning on Debian/Ubuntu"
        source lib/debian.sh
    elif [ -f /etc/redhat-release ] || [ -f /etc/rocky-release ]; then
        echo -e "\n\nRunning on Red Hat / CentOS / Fedora / Rocky"
        source lib/redhat.sh
    fi
fi

# Docker setup
echo "Setting up Docker..."
if ! command_exists docker; then
    if [ "$(uname)" == "Darwin" ]; then
        brew install --cask docker
    elif [ -f /etc/rocky-release ]; then
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    else
        curl -fsSL https://get.docker.com | sudo sh
    fi
    # Install Docker Compose
    sudo curl -sSL "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VER}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker already installed"
fi

# Linux-specific Docker setup
if [ "$(uname)" != "Darwin" ]; then
    # Add current user to Docker group
    if ! groups $USER | grep -q '\bdocker\b'; then
        echo "Adding user to 'docker' group..."
        sudo usermod -aG docker $USER
    fi
    if [ $(id -gn) != "docker" ]; then
        exec sg docker "$0 $@"
    fi

    # Configure Docker service
    if ! systemctl is-active --quiet docker; then
        sudo systemctl enable docker
        sudo systemctl start docker
    else
        echo "Docker service already running"
    fi
fi

docker version
docker-compose --version

# Install essential packages
echo "Installing essential packages..."
essential_packages=(curl wget unzip jq xsel xclip ruby rubygems nodejs npm byacc fontconfig)
for package in "${essential_packages[@]}"; do
    install_package "$package"
done

# Install language-specific packages
echo "Installing language-specific packages..."
# Ruby gems
ruby_gems=(wbench neovim ruby-beautify starscope seeing_is_believing rubocop haml_lint scss-lint mdl)
for gem in "${ruby_gems[@]}"; do
    install_gem "$gem"
done

# Global npm packages
npm_packages=(prettier neovim bash-language-server eslint jsonlint typescript js-beautify)
for package in "${npm_packages[@]}"; do
    install_npm_package "$package"
done

# Some package in npm installs packer. Fix packer conflict from cracklib-dicts
sudo unlink /usr/sbin/packer || :

# Python packages
if [ ! -d "$HOME/.venv" ]; then
    python3 -m venv ~/.venv
fi
source ~/.venv/bin/activate
python_packages=(neovim pre-commit ruamel.yaml runlike awscli "vim-vint==0.3.21" pip_search howdoi)
for package in "${python_packages[@]}"; do
    install_pip_package "$package"
done
deactivate

# Install additional tools
echo "Installing additional tools..."
install_tool "terraform" "$TF_VER" "wget https://releases.hashicorp.com/terraform/$TF_VER/terraform_${TF_VER}_linux_amd64.zip && sudo unzip terraform_${TF_VER}_linux_amd64.zip -d /usr/local/bin/ && rm terraform_${TF_VER}_linux_amd64.zip*"
install_tool "packer" "$PACKER_VER" "wget https://releases.hashicorp.com/packer/$PACKER_VER/packer_${PACKER_VER}_linux_amd64.zip && sudo unzip packer_${PACKER_VER}_linux_amd64.zip -d /usr/local/bin/ && rm packer_${PACKER_VER}_linux_amd64.zip*"
install_tool "drone" "$DRONE_VER" "pushd drone && curl -L https://github.com/drone/drone-cli/releases/download/v${DRONE_VER}/drone_linux_amd64.tar.gz | tar zx && sudo install -t /usr/local/bin drone && rm drone && popd"
install_tool "codiff" "" "curl -LO https://storage.googleapis.com/container-diff/latest/container-diff-linux-amd64 && chmod +x container-diff-linux-amd64 && sudo mv container-diff-linux-amd64 /usr/local/bin/codiff"

# Setup Minikube
install_tool "minikube" "" "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64"
if ! minikube status | grep -q "Running"; then
    minikube start
    echo "minikube setup done"
else
    echo "Minikube is already running"
fi

# Install Hub tool
if ! command_exists hub; then
    echo "Installing Hub tool..."
    mkdir -p hub && pushd hub
    curl -sSL "https://github.com/github/hub/releases/download/v${HUB_VER}/hub-linux-amd64-${HUB_VER}.tgz" | \
    tar xz --strip-components=1 && sudo install -m 755 bin/hub /usr/local/bin/hub
    cp -f etc/hub.bash_completion.sh ~/.hub.bash_completion.sh
    cp -rf share/vim/vimfiles/* ~/.dotfiles/config/nvim/
    popd && rm -rf hub
fi

# Install tmux and salt
if ! command_exists tmux; then sudo bash tmux/install.sh; fi
if ! command_exists salt-call; then sudo bash salt/install.sh; fi

# Set up Docker auto-clean cron jobs
(crontab -l 2>/dev/null | grep -q "docker system prune -f") || (crontab -l 2>/dev/null; echo "0 * * * * /usr/bin/docker system prune -f") | crontab -
(crontab -l 2>/dev/null | grep -q "docker system prune -af") || (crontab -l 2>/dev/null; echo "0 0 * * * /usr/bin/docker system prune -af") | crontab -

# Terminal setup
echo "Setting up terminal..."
if [ ! -f "$HOME/.terminfo/t/tmux-256color" ]; then
    echo "Adding terminal colors..."
    tic resources/tmux-256color.terminfo
    tic resources/xterm-256color-italic.terminfo
    tic resources/tmux-256color-italic.terminfo
fi
# Add terminal colors
cat <<EOF|tic -x -
tmux|tmux terminal multiplexer,
ritm=\E[23m, rmso=\E[27m, sitm=\E[3m, smso=\E[7m, Ms@,
use=xterm+tmux, use=screen,

tmux-256color|tmux with 256 colors,
use=xterm-256color, use=tmux,
EOF

# Install Nerd Fonts
if [ ! -d ~/.local/share/fonts ] || ! ls ~/.local/share/fonts | grep -q "NerdFont"; then
    mkdir -p ~/.local/share/fonts && pushd ~/.local/share/fonts
    for font in DroidSansMono FiraCode; do
        curl -sSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/${font}.tar.xz" | tar xJ
    done
    fc-cache -f
    popd
else
    echo "Nerd Fonts already installed"
fi

# Download and install various utility scripts
[ ! -f ~/.bash-preexec.sh ] && curl https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh > ~/.bash-preexec.sh
[ ! -f ~/.git-prompt.sh ] && curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh > ~/.git-prompt.sh
if [ ! -f /usr/local/bin/diff-so-fancy ]; then
    sudo mkdir -p /usr/local/bin/lib
    sudo bash -c "curl https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/diff-so-fancy > /usr/local/bin/diff-so-fancy"
    sudo bash -c "curl https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/lib/DiffHighlight.pm > /usr/local/bin/lib/DiffHighlight.pm"
    sudo chmod +x /usr/local/bin/diff-so-fancy
fi

# Set up Drone configuration
cd ~/.dotfiles
sudo cp -R drone /etc/
SECRET=`openssl rand -hex 32`
sudo crudini --set /etc/drone/agent.env '' DRONE_SECRET $SECRET
sudo crudini --set /etc/drone/server.env '' DRONE_SECRET $SECRET

# Dotfiles setup
echo "Setting up dotfiles..."
source lib/link.sh

# Vim setup
echo "Setting up Vim..."
export XDG_CONFIG_HOME=$HOME/.config
sed -i 's/^colorscheme tender$/" \0/' config/nvim/init.vim
nvim +PlugInstall +qall
git checkout -- config/nvim/init.vim
nvim +UpdateRemotePlugins +qall

# Copilot setup for neovim
git clone https://github.com/github/copilot.vim.git ~/.config/nvim/pack/github/start/copilot.vim

# Create local override files
touch ~/.vimrc.local ~/.bash_profile.local ~/.dotfilesrc

# Install tmux plugins
if [ ! -d "$HOME/.tmux/plugins/tpm" ] || [ ! "$(ls -A "$HOME/.tmux/plugins/tpm")" ]; then
    /usr/local/bin/tmux start-server
    /usr/local/bin/tmux new-session -d
    bash ~/.tmux/plugins/tpm/scripts/install_plugins.sh
    /usr/local/bin/tmux kill-server || :
else
    echo "tmux plugins already installed"
fi

echo "Setup complete. Please review any error messages and restart your shell."
