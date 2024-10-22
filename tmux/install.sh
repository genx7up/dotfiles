#!/bin/bash

set -e

# Enable debug mode if '--debug' is the last argument
[[ ${@: -1} == '--debug' ]] && set -x

LIBEVENT_VER=2.1.12
TMUX_VER=3.3a
FZF_VER=0.42.0

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
elif [ "$(uname)" == "Darwin" ]; then
    OS="macos"
else
    echo "Unsupported OS"
    exit 1
fi

# Install dependencies
case $OS in
    "rhel"|"centos")
        sudo yum -y install gcc kernel-devel make ncurses-devel
        ;;
    "debian"|"ubuntu")
        sudo apt-get update && sudo apt-get install -y gcc make libncurses5-dev libevent-dev
        ;;
    "macos")
        brew update && brew install gcc make ncurses libevent
        ;;
esac

# DOWNLOAD SOURCES FOR LIBEVENT AND MAKE AND INSTALL
curl -OL https://github.com/libevent/libevent/releases/download/release-$LIBEVENT_VER-stable/libevent-$LIBEVENT_VER-stable.tar.gz
tar -xvzf libevent-$LIBEVENT_VER-stable.tar.gz
cd libevent-$LIBEVENT_VER-stable
./configure --prefix=/usr/local
make
sudo make install
cd ..

# DOWNLOAD SOURCES FOR TMUX AND MAKE AND INSTALL
curl -OL https://github.com/tmux/tmux/releases/download/$TMUX_VER/tmux-$TMUX_VER.tar.gz
tar -xvzf tmux-$TMUX_VER.tar.gz
cd tmux-$TMUX_VER
LDFLAGS="-L/usr/local/lib -Wl,-rpath=/usr/local/lib" ./configure --prefix=/usr/local
make
sudo make install
cd ..

# Install fzf
case $OS in
    "rhel"|"centos"|"debian"|"ubuntu")
        wget https://github.com/junegunn/fzf/releases/download/$FZF_VER/fzf-$FZF_VER-linux_amd64.tar.gz
        tar xvf fzf-$FZF_VER-linux_amd64.tar.gz
        sudo mv fzf /usr/local/bin/
        ;;
    "macos")
        brew install fzf
        ;;
esac

#cleanup
rm -rf libevent-$LIBEVENT_VER-stable*
rm -rf tmux-$TMUX_VER*
rm -rf fzf-$FZF_VER*
