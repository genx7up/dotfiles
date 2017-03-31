#!/bin/bash
set -e

if [[ ${@: -1} == '--debug' ]];then
	set -x
fi

SRC_DIR=~/src
mkdir -p "$SRC_DIR"

if [ "$(uname)" == "Darwin" ]; then
    # Do something under Mac OS X platform        
    xcode-select --install

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
    
    #install pre-requiste
	sudo yum -y install git
fi

#get personal git keys
bash /usr/local/bin/volt.sh login

if [[ ! -f ~/.ssh/git_rsa.pub ]]; then 
	mkdir -p ~/.ssh && chmod 660 ~/.ssh
	bash /usr/local/bin/volt.sh get git_rsa.pub > ~/.ssh/git_rsa.pub
	bash /usr/local/bin/volt.sh get git_rsa > ~/.ssh/git_rsa
	chmod 600 ~/.ssh/git_rsa
	
	if [[ $? == 0 && `cat ~/.ssh/git_rsa.pub` == "Not found" ]]; then
		echo 'No git keys found. Do you want to generate & add new keys? (y/n)'
		read choice < /dev/tty
		if [[ $choice == 'y' ]]; then
			ssh-keygen -t rsa -b 4096 -f ~/.ssh/git_rsa
			if [[ -f ~/.ssh/git_rsa.pub ]]; then 
				echo 'Save new keys to remote vault? (y/n)'
				read choice < /dev/tty
				if [[ $choice == 'y' ]]; then
					bash /usr/local/bin/volt.sh set git_rsa.pub @/root/.ssh/git_rsa.pub
					bash /usr/local/bin/volt.sh set git_rsa @/root/.ssh/git_rsa
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

./install/backup.sh
./install.sh

# Customize git
RES=$(git config --global user.name | wc -l)
if [[ "$RES" == "0" ]]; then
	printf "\n### Enter user.name for Git Commits\n"
	read name < /dev/tty
	set -x
	git config --global user.name $name
	git config --global user.email "$name@users.noreply.github.com"
	set +x
fi

printf "\n### Done. Exit & Relogin\n"
