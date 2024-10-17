#!/bin/bash
set -e

# Enable debug mode if '--debug' is the last argument
[[ ${@: -1} == '--debug' ]] && set -x

echo "Creating/Syncing IDE environment ..."

SRC_DIR=~/src
mkdir -p "$SRC_DIR"

# OS-specific setup for git
if [ "$(uname)" == "Darwin" ]; then
    # macOS setup
    xcode-select --install || true
elif [ "$(uname -s)" == "Linux" ]; then
    # Linux setup
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y git
    elif [ -f /etc/redhat-release ]; then
        # Red Hat/CentOS/Fedora
        if [ "$(rpm --eval '%{centos_ver}')" == "7" ]; then
            echo "Warning: CentOS 7 is deprecated. Consider upgrading to a newer OS."
            ###### Install latest git from Rackspace repo
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

# Setup Volt and retrieve git keys
sudo rm -rf /usr/local/bin/volt.sh
sudo curl -sSL https://s7k-prod.s3.us-west-2.amazonaws.com/vault/nclans/client/volt.sh -o /usr/local/bin/volt.sh
bash /usr/local/bin/volt.sh login

# Git SSH key setup
if [[ ! -f ~/.ssh/git_rsa.pub ]]; then
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    bash /usr/local/bin/volt.sh get misc/tokens/git_rsa.pub > ~/.ssh/git_rsa.pub
    bash /usr/local/bin/volt.sh get misc/tokens/git_rsa > ~/.ssh/git_rsa
    chmod 600 ~/.ssh/git_rsa

	if [[ $? == 0 && `cat ~/.ssh/git_rsa.pub` == "Not found" ]]; then
		rm -rf ~/.ssh/git_rsa*
		echo 'No git keys found. Do you want to generate & add new keys? (y/n)'
		read choice < /dev/tty
		if [[ $choice == 'y' ]]; then
			ssh-keygen -t rsa -b 4096 -f ~/.ssh/git_rsa -q -N ""
			if [[ -f ~/.ssh/git_rsa.pub ]]; then
				echo 'Copy/Paste the following public key to your git profile at github, bitbucket etc.'
				cat ~/.ssh/git_rsa.pub
				echo 'Reusability - Save new keys to remote vault? (y/n)'
				read choice < /dev/tty
				if [[ $choice == 'y' ]]; then
					bash /usr/local/bin/volt.sh set misc/tokens/git_rsa.pub @$HOME/.ssh/git_rsa.pub
					bash /usr/local/bin/volt.sh set misc/tokens/git_rsa @$HOME/.ssh/git_rsa
				fi
			fi
		fi
	fi
fi
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
./install.sh || echo $?

# Configure git user if not set
if [[ -z $(git config user.name) ]]; then
    printf "\n### Enter user.name for Git Commits\n"
    read -r name
    git config user.name "$name"
    git config user.email "$name@users.noreply.github.com"
fi

printf "\n### Done. Reload your terminal ###\n\n"
read -t 10 -p "Exiting terminal in 10s ... ^C to abort" || true
