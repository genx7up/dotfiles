#!/bin/bash
set -e

if [[ ${@: -1} == '--debug' ]];then
	set -x
fi

echo "Creating/Syncing IDE environment ..."
#read -t 5 -p "Running 'idesync' in 5s ... ^C to abort" || echo $?

SRC_DIR=~/src
mkdir -p "$SRC_DIR"

if [ "$(uname)" == "Darwin" ]; then
    # Do something under Mac OS X platform
    xcode-select --install && echo $?

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform

    ###### Install latest git from Rackspace repo
    sudo yum -y install https://repo.ius.io/ius-release-el7.rpm || :
    sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm || :
    sudo yum -y install git236
fi

#get personal git keys
sudo rm -rf /usr/local/bin/volt.sh
sudo curl -sSL https://raw.githubusercontent.com/genx7up/dotfiles/master/misc/volt.sh -o /usr/local/bin/volt.sh
bash /usr/local/bin/volt.sh login

if [[ ! -f ~/.ssh/git_rsa.pub ]]; then
	mkdir -p ~/.ssh && chmod 700 ~/.ssh
	bash /usr/local/bin/volt.sh get git_rsa.pub > ~/.ssh/git_rsa.pub
	bash /usr/local/bin/volt.sh get git_rsa > ~/.ssh/git_rsa
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
					bash /usr/local/bin/volt.sh set git_rsa.pub @$HOME/.ssh/git_rsa.pub
					bash /usr/local/bin/volt.sh set git_rsa @$HOME/.ssh/git_rsa
				fi
			fi
		fi
	fi
fi
source /usr/local/bin/volt.sh load

# dotfiles
if [[ ! -d ~/.dotfiles ]]; then
	git clone https://github.com/genx7up/dotfiles.git ~/.dotfiles
fi
cd ~/.dotfiles && git pull

ssh-keyscan -H github.com >> ~/.ssh/known_hosts
git remote set-url origin git@github.com:genx7up/dotfiles.git
git pull || echo "Your key is not registered with Github. You will not be able to update dotfiles."

./lib/backup.sh
./install.sh || echo $?

# Customize git
RES=$(git config user.name | wc -l)
if [[ "$RES" == "0" ]]; then
	printf "\n### Enter user.name for Git Commits\n"
	read name < /dev/tty
	set -x
	git config user.name $name
	git config user.email "$name@users.noreply.github.com"
	set +x
fi

printf "\n### Done. Reload your terminal ###\n\n"
read -t 10 -p "Exiting terminal in 10s ... ^C to abort" || echo $?



