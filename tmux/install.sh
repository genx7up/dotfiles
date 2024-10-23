#!/bin/bash

set -e

# Enable debug mode if '--debug' is the last argument
[[ ${@: -1} == '--debug' ]] && set -x

# Define versions
LIBEVENT_VER=2.1.12
TMUX_VER=3.4
FZF_VER=0.46.1

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ "$(uname)" == "Darwin" ]; then
        echo "macos"
    else
        echo "unsupported"
    fi
}

# Function to compare versions
version_compare() {
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}

# Function to install dependencies
install_dependencies() {
    local os=$1
    echo "Checking dependencies for $os..."
    case $os in
        "rhel"|"centos"|"rocky")
            if ! rpm -q gcc kernel-devel make ncurses-devel &>/dev/null; then
                echo "Installing missing dependencies for RHEL/CentOS/Rocky..."
                sudo yum -y install gcc kernel-devel make ncurses-devel
            else
                echo "Dependencies already installed for RHEL/CentOS/Rocky"
            fi
            ;;
        "debian"|"ubuntu")
            if ! dpkg -s gcc make libncurses5-dev &>/dev/null; then
                echo "Installing missing dependencies for Debian/Ubuntu..."
                sudo apt-get update && sudo apt-get install -y gcc make libncurses5-dev
            else
                echo "Dependencies already installed for Debian/Ubuntu"
            fi
            ;;
        "macos")
            missing_deps=()
            for dep in gcc make ncurses; do
                if ! brew list | grep -q "^$dep$"; then
                    missing_deps+=($dep)
                fi
            done
            if [ ${#missing_deps[@]} -ne 0 ]; then
                echo "Installing missing dependencies for macOS: ${missing_deps[*]}"
                brew update && brew install ${missing_deps[@]}
            else
                echo "Dependencies already installed for macOS"
            fi
            ;;
        *)
            echo "Unsupported OS for dependency installation"
            exit 1
            ;;
    esac
}

# Function to install libevent
install_libevent() {
    if ! pkg-config --exists libevent || version_compare "$(pkg-config --modversion libevent)" "$LIBEVENT_VER"; then
        echo "Installing libevent $LIBEVENT_VER..."
        curl -OL "https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VER}-stable/libevent-${LIBEVENT_VER}-stable.tar.gz"
        tar -xzf "libevent-${LIBEVENT_VER}-stable.tar.gz"
        cd "libevent-${LIBEVENT_VER}-stable"
        ./configure --prefix=/usr/local
        make
        sudo make install
        cd ..
    else
        echo "libevent $LIBEVENT_VER is already installed"
    fi
}

# Function to install tmux
install_tmux() {
    if ! command -v tmux &> /dev/null || version_compare "$(tmux -V | cut -d' ' -f2)" "$TMUX_VER"; then
        echo "Installing tmux $TMUX_VER..."
        curl -OL "https://github.com/tmux/tmux/releases/download/${TMUX_VER}/tmux-${TMUX_VER}.tar.gz"
        tar -xzf "tmux-${TMUX_VER}.tar.gz"
        cd "tmux-${TMUX_VER}"
        LDFLAGS="-L/usr/local/lib -Wl,-rpath=/usr/local/lib" ./configure --prefix=/usr/local
        make
        sudo make install
        cd ..
    else
        echo "tmux $TMUX_VER is already installed"
    fi
}

# Function to install fzf
install_fzf() {
    local os=$1
    if ! command -v fzf &> /dev/null || version_compare "$(fzf --version)" "$FZF_VER"; then
        echo "Installing fzf $FZF_VER..."
        case $os in
            "rhel"|"centos"|"rocky"|"debian"|"ubuntu")
                wget "https://github.com/junegunn/fzf/releases/download/${FZF_VER}/fzf-${FZF_VER}-linux_amd64.tar.gz"
                tar xf "fzf-${FZF_VER}-linux_amd64.tar.gz"
                sudo mv fzf /usr/local/bin/
                ;;
            "macos")
                brew install fzf
                ;;
        esac
    else
        echo "fzf $FZF_VER is already installed"
    fi
}

# Main execution flow
main() {
    local os=$(detect_os)
    
    if [ "$os" == "unsupported" ]; then
        echo "Unsupported OS"
        exit 1
    fi

    install_dependencies "$os"
    install_libevent
    install_tmux
    install_fzf "$os"

    # Cleanup
    rm -rf libevent-${LIBEVENT_VER}-stable* tmux-${TMUX_VER}* fzf-${FZF_VER}* 2>/dev/null

    echo "Installation completed successfully"
}

# Run the main function
main
