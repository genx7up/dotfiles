#!/bin/bash
set -e

# Enable debug mode if '--debug' is the last argument
[[ ${@: -1} == '--debug' ]] && set -x

echo "Creating/Syncing IDE environment ..."

# Function to check if a command exists
command_exists() {
    type "$1" > /dev/null 2>&1
}

SRC_DIR=~/src
mkdir -p "$SRC_DIR"

# Function to install git on different OS and distributions
install_git() {
    if [ "$(uname)" == "Darwin" ]; then
        xcode-select --install || true
    elif [ "$(uname -s)" == "Linux" ]; then
        if [ -f /etc/debian_version ]; then
            sudo apt-get update
            sudo apt-get install -y git
        elif [ -f /etc/redhat-release ] || [ -f /etc/rocky-release ]; then
            if [ -f /etc/centos-release ] && grep -q "CentOS Linux release 7" /etc/centos-release; then
                echo "Warning: CentOS 7 is deprecated. Consider upgrading to a newer OS."
                # Install latest git from Rackspace repo
                sudo yum -y install https://repo.ius.io/ius-release-el7.rpm || :
                sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm || :
                sudo yum -y install git236
            else
                sudo yum -y install git
            fi
        else
            echo "Unsupported Linux distribution"
            exit 1
        fi
    else
        echo "Unsupported operating system"
        exit 1
    fi
}

# Install git
install_git

# Setup Volt and retrieve git keys
sudo rm -rf /usr/local/bin/volt.sh
sudo curl -sSL https://s7k-prod.s3.us-west-2.amazonaws.com/vault/nclans/client/volt.sh -o /usr/local/bin/volt.sh
bash /usr/local/bin/volt.sh login

# Function to setup Git SSH keys
setup_git_ssh_keys() {
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    bash /usr/local/bin/volt.sh get misc/tokens/git_rsa.pub > ~/.ssh/git_rsa.pub
    bash /usr/local/bin/volt.sh get misc/tokens/git_rsa > ~/.ssh/git_rsa
    chmod 600 ~/.ssh/git_rsa

    if [[ $? == 0 && $(cat ~/.ssh/git_rsa.pub) == "Not found" ]]; then
        rm -rf ~/.ssh/git_rsa*
        echo 'No git keys found. Do you want to generate & add new keys? (y/n)'
        read -r choice < /dev/tty
        if [[ $choice == 'y' ]]; then
            ssh-keygen -t rsa -b 4096 -f ~/.ssh/git_rsa -q -N ""
            if [[ -f ~/.ssh/git_rsa.pub ]]; then
                echo 'Copy/Paste the following public key to your git profile at github, bitbucket etc.'
                cat ~/.ssh/git_rsa.pub
                echo 'Reusability - Save new keys to remote vault? (y/n)'
                read -r choice < /dev/tty
                if [[ $choice == 'y' ]]; then
                    bash /usr/local/bin/volt.sh set misc/tokens/git_rsa.pub @"$HOME"/.ssh/git_rsa.pub
                    bash /usr/local/bin/volt.sh set misc/tokens/git_rsa @"$HOME"/.ssh/git_rsa
                fi
            fi
        fi
    fi
}

# Git SSH key setup
[[ ! -f ~/.ssh/git_rsa.pub ]] && setup_git_ssh_keys

source /usr/local/bin/volt.sh load

# Setup dotfiles
if [[ ! -d ~/.dotfiles ]]; then
    git clone https://github.com/genx7up/dotfiles.git ~/.dotfiles
fi
cd ~/.dotfiles && git pull

ssh-keyscan -H github.com >> ~/.ssh/known_hosts
git remote set-url origin git@github.com:genx7up/dotfiles.git
git pull || echo "Your key is not registered with Github. You will not be able to update dotfiles."

./lib/backup.sh
./install.sh

# Configure git user if not set
if [[ -z $(git config user.name) ]]; then
    printf "\n### Enter user.name for Git Commits\n"
    read -r name
    git config user.name "$name"
    git config user.email "$name@users.noreply.github.com"
fi

# Validate installations
echo "Validating installations..."

# Common tools across platforms
tools_to_check=(gcc python3 ruby node npm docker docker-compose gh nvim tmux terraform packer drone codiff hub minikube wget unzip jq pip gem yamllint shellcheck)
for tool in "${tools_to_check[@]}"; do
    command_exists $tool && echo "$tool: OK" || echo "$tool: Not found"
done

# Check for Nerd Fonts
[ -d "$HOME/.local/share/fonts" ] && ls "$HOME/.local/share/fonts" | grep -q "NerdFont" && echo "Nerd Fonts: OK" || echo "Nerd Fonts: Not found"

# Check for tmux plugins
[ -d "$HOME/.tmux/plugins" ] && [ "$(ls -A "$HOME/.tmux/plugins")" ] && echo "tmux plugins: OK" || echo "tmux plugins: Not found"

# Version checks for critical tools
for tool in docker docker-compose terraform packer; do
    $tool --version
done
nvim --version | head -n 1

echo "Validation complete. Please review the output for any missing or incorrectly installed software."

printf "\n### Done. Reload your terminal ###\n\n"
read -t 10 -p "Exiting terminal in 10s ... ^C to abort" || true
