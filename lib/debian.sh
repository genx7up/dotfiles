#!/usr/bin/env bash

set -e

# Update package lists
sudo apt-get update

# Install essential packages
sudo apt-get install -y \
    ack \
    findutils \
    fzf \
    git \
    git-lfs \
    gnupg \
    gnupg-agent \
    sed \
    grep \
    highlight \
    httpie \
    imagemagick \
    jq \
    lua5.4 \
    vim-gtk3 \
    neovim \
    p7zip-full \
    pigz \
    pv \
    rename \
    ripgrep \
    rhino \
    ruby \
    shellcheck \
    speedtest-cli \
    ssh \
    testssl.sh \
    silversearcher-ag \
    tmux \
    tree \
    unison \
    vbindiff \
    wget \
    yamllint \
    zsh

# Install build essentials and Python
sudo apt-get install -y gcc g++ make python3-pip python3-dev

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install font tools
sudo apt-get install -y \
    fontforge \
    woff-tools \
    woff2

# Install Nerd Fonts
mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/DroidSansMono.tar.xz
tar xvf DroidSansMono.tar.xz && rm DroidSansMono.tar.xz
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.tar.xz
tar xvf FiraCode.tar.xz && rm FiraCode.tar.xz
fc-cache -fv

# Install GitHub CLI (replacing Hub)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# Install Keybase
curl --remote-name https://prerelease.keybase.io/keybase_amd64.deb
sudo apt install ./keybase_amd64.deb
rm keybase_amd64.deb

echo "Software updated ..."
