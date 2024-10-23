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
        sudo $PKG_MANAGER -y install "$1"
    else
        echo "$1 already installed"
    fi
}

# Function to install EPEL repository
install_epel() {
    echo "Installing EPEL repository..."
    sudo $PKG_MANAGER check-update || true
    sudo $PKG_MANAGER install -y 'dnf-command(config-manager)'
    install_package epel-release
    if [ "$VER" -ge 8 ]; then
        sudo $PKG_MANAGER install -y dnf-plugins-core
        if [ "$OS" = "Rocky Linux" ]; then
            sudo $PKG_MANAGER config-manager --set-enabled crb
        else
            sudo $PKG_MANAGER config-manager --set-enabled powertools
        fi
    fi
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
    echo "Checking Neovim installation..."
    if ! command -v nvim &> /dev/null || [[ $(nvim --version | head -n1 | cut -d' ' -f2) < "0.5" ]]; then
        sudo $PKG_MANAGER install -y ninja-build gettext cmake unzip curl gcc-c++ make
        if [ "$VER" -lt 8 ]; then
            sudo $PKG_MANAGER remove cmake -y
            sudo $PKG_MANAGER install cmake3 -y
            sudo ln -s /usr/bin/cmake3 /usr/bin/cmake
        fi
        rm -rf neovim && git clone https://github.com/neovim/neovim
        pushd neovim && git checkout stable
        make CMAKE_BUILD_TYPE=RelWithDebInfo
        sudo make install
        popd && rm -rf neovim
    else
        echo "Neovim is already installed and up to date."
    fi
}

# Function to install Node.js
install_nodejs() {
    if ! command_exists node; then
        echo "Installing Node.js..."
        if [ "$VER" -ge 8 ]; then
            sudo $PKG_MANAGER install nodejs -y
        else
            curl -sL https://rpm.nodesource.com/setup_16.x | sudo -E bash -
            sudo $PKG_MANAGER install -y nodejs
        fi
    else
        echo "Node.js already installed"
    fi
}

# Function to install GitHub CLI
install_github_cli() {
    if ! command_exists gh; then
        echo "Installing GitHub CLI..."
        sudo $PKG_MANAGER config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo $PKG_MANAGER install -y gh
    else
        echo "GitHub CLI already installed"
    fi
}

# Function to determine the OS and version
get_os_info() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$(echo $VERSION_ID | cut -d. -f1)
    elif [ -f /etc/redhat-release ]; then
        OS=$(cat /etc/redhat-release | cut -d' ' -f1)
        VER=$(sed -n 's/.*release \([0-9]\+\).*/\1/p' /etc/redhat-release)
    else
        echo "Unsupported OS" >&2
        exit 1
    fi
}

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
    get_os_info
    
    if [ -n "$VER" ] && [ "$VER" -ge 8 ]; then
        PKG_MANAGER="dnf"
    else
        PKG_MANAGER="yum"
    fi

    install_epel

    # List of packages to install
    packages=(
        gcc-c++ wget unzip tree bash-completion jq xorg-x11-xauth
        python3 python3-pip python3-devel xclip ncurses-term ack the_silver_searcher tcpdump bind-utils crudini yamllint ShellCheck
        bzip2 gcc kernel-devel make ncurses-devel tidy device-mapper-persistent-data lvm2
    )

    if [ "$VER" -ge 8 ]; then
        packages+=(
            dnf-utils
            procps-ng  # Provides 'ps' command
        )
    else
        packages+=(
            yum-utils
            bash-completion-extras
            elixir
        )
    fi

    for package in "${packages[@]}"; do
        install_package "$package"
    done

    install_nodejs
    install_github_cli
    install_or_update_neovim
    configure_selinux

    echo "Software updated ..."
}

# Run the main function
main
