# Install tmux on rhel/centos 7

LIBEVENT_VER=2.1.8
TMUX_VER=2.7
FZF_VER=0.17.4

# install deps
yum -y install gcc kernel-devel make ncurses-devel

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

wget https://github.com/junegunn/fzf-bin/releases/download/$FZF_VER/fzf-$FZF_VER-linux_amd64.tgz
tar xvf fzf-$FZF_VER-linux_amd64.tgz
mv fzf /usr/local/bin/

#cleanup
rm -rf libevent-$LIBEVENT_VER-stable*
rm -rf tmux-$TMUX_VER*
rm -rf fzf-$FZF_VER*

