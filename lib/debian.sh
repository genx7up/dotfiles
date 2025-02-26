#!/usr/bin/env bash

set -e

# Enable debug mode if '--debug' is the last argument
[[ ${@: -1} == '--debug' ]] && set -x

# Function to install a package if not already installed
install_if_missing() {
    if ! dpkg -s "$1" &> /dev/null; then
        sudo DEBIAN_FRONTEND=noninteractive UCF_FORCE_CONFFOLD=1 apt-get install -y "$1"
    fi
}

# Function to install GitHub CLI
install_github_cli() {
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh -y
    gh auth login --with-token < ~/.github_patoken
    gh extension install github/gh-copilot
    gh copilot version
}

# Function to install or update Neovim
install_or_update_neovim() {
    sudo apt-get install -y ninja-build gettext cmake unzip curl
    git clone https://github.com/neovim/neovim
    cd neovim && git checkout stable
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    cd .. && rm -rf neovim
}

# No popup, use existing config
echo 'DPkg::Options {"--force-confdef"; "--force-confold";};' | sudo tee /etc/apt/apt.conf.d/99force-conf

# Update package lists
sudo apt-get update

# List of packages to install
packages=(
    ack apt-transport-https bash-completion bzip2 ca-certificates crudini cron curl dnsutils
    elixir findutils fontforge fzf g++ gcc git git-lfs gnupg gnupg-agent grep highlight
    httpie imagemagick jq libssl-dev lsb-release lua5.4 make ncurses-term openssl
    p7zip-full pigz pv python3 python3-dev python3-full python3-pip python3-neovim rename rhino ripgrep ruby
    ruby-dev sed shellcheck silversearcher-ag speedtest-cli ssh tcpdump testssl.sh tidy
    tree unison unzip vbindiff vim-gtk3 wget woff-tools woff2 xclip yamllint zsh locales
)

# Install packages
echo "Installing base packages..."
for package in "${packages[@]}"; do
    install_if_missing "$package"
done

# Check if the locale en_US.UTF-8 is already generated
locale_check=$(locale -a | grep -q en_US.utf8 && echo "found" || echo "")
if [ -z "$locale_check" ]; then
    echo "en_US.UTF-8 locale not found, generating it..."
    sudo sed -i '/^# *en_US\.UTF-8/s/^# *//' /etc/locale.gen
    sudo locale-gen en_US.UTF-8
else
    echo "en_US.UTF-8 locale is already generated."
fi
# Check if LANG is set to en_US.UTF-8
current_lang=$(locale | grep LANG=)
if [[ "$current_lang" != "LANG=en_US.UTF-8" ]]; then
    echo "Updating system locale to en_US.UTF-8..."
    sudo update-locale LANG=en_US.UTF-8
else
    echo "System locale is already set to en_US.UTF-8."
fi

# Install Node.js and npm
echo "Checking Node.js installation..."
if ! command -v node &> /dev/null; then
    echo "Installing Node.js and npm..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Install GitHub CLI
echo "Checking GitHub CLI installation..."
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    install_github_cli
else
    echo "GitHub CLI already installed"
fi

# Install Keybase
echo "Checking Keybase installation..."
if ! command -v keybase &> /dev/null; then
    echo "Installing Keybase..."
    curl --remote-name https://prerelease.keybase.io/keybase_amd64.deb
    sudo apt install ./keybase_amd64.deb -y
    rm keybase_amd64.deb
fi

# Install or update Neovim
echo "Checking Neovim installation..."
if ! command -v nvim &> /dev/null || [[ $(nvim --version | head -n1 | cut -d' ' -f2) < "0.5" ]]; then
    echo "Installing or updating Neovim..."
    install_or_update_neovim
fi

echo "Software installation and updates completed."
