#!/usr/bin/env bash

set -e

# Enable debug mode if '--debug' is the last argument
[[ ${@: -1} == '--debug' ]] && set -x

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package if not already installed
install_package() {
    if ! rpm -q "$1" > /dev/null 2>&1; then
        sudo yum -y install "$1"
    else
        echo "$1 already installed"
    fi
}

# Function to update package lists
update_packages() {
    echo "Updating package lists..."
    sudo yum check-update
}

# Function to install EPEL repository
install_epel() {
    echo "Installing EPEL repository..."
    install_package epel-release
}

# Function to install packages from a list
install_packages() {
    local packages=("$@")
    echo "Installing packages..."
    for package in "${packages[@]}"; do
        install_package "$package"
    done
}

# Function to install or update Neovim
install_or_update_neovim() {
    sudo yum install -y ninja-build gettext cmake unzip curl gcc-c++ make
    git clone https://github.com/neovim/neovim
    cd neovim && git checkout stable
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    sudo make install
    cd .. && rm -rf neovim
}

# Function to install Node.js
install_nodejs() {
    if ! command_exists node; then
        echo "Installing Node.js..."
        sudo yum install https://rpm.nodesource.com/pub_16.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y
        sudo yum install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1
    else
        echo "Node.js already installed"
    fi
}

# Function to install GitHub CLI
install_github_cli() {
    if ! command_exists gh; then
        echo "Installing GitHub CLI..."
        VER=$(sed -n 's/.*release \([0-9]\+\).*/\1/p' /etc/redhat-release)
        if [ "$VER" -lt 8 ]; then
            LATEST_VERSION=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep tag_name | cut -d '"' -f 4)
            sudo yum install -y "https://github.com/cli/cli/releases/download/v${LATEST_VERSION}/gh_${LATEST_VERSION}_linux_amd64.rpm"
        else
            sudo dnf install -y 'dnf-command(config-manager)'
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo dnf install -y gh
        fi
    else
        echo "GitHub CLI already installed"
    fi
}

# Install or update Neovim
echo "Checking Neovim installation..."
if ! command -v nvim &> /dev/null || [[ $(nvim --version | head -n1 | cut -d' ' -f2) < "0.5" ]]; then
    echo "Installing or updating Neovim..."
    install_or_update_neovim
fi

# Function to configure SELinux for Docker
configure_selinux() {
    current_selinux_status=$(getenforce)
    if [ "$current_selinux_status" = "Enforcing" ]; then
        echo "Changing SELinux to permissive mode..."
        sudo setenforce 0
        sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
    else
        echo "SELinux is already in permissive or disabled mode. No changes needed."
    fi
}

# Main execution
main() {
    update_packages
    install_epel

    # List of packages to install
    packages=(
        gcc-c++ wget unzip tree bash-completion bash-completion-extras jq xorg-x11-xauth
        python3 python3-pip python3-devel xclip ncurses-term ack the_silver_searcher tcpdump bind-utils crudini yamllint ShellCheck
        bzip2 gcc kernel-devel make ncurses-devel elixir tidy yum-utils device-mapper-persistent-data lvm2
    )

    install_packages "${packages[@]}"
    install_nodejs
    install_github_cli
    install_neovim
    configure_selinux

    echo "Software updated ..."
}

# Run the main function
main
