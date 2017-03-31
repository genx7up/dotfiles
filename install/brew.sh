#!/bin/sh

# Check for Homebrew
if test ! $(which brew)
then
  echo "  Installing Homebrew for you."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" > /tmp/homebrew-install.log
fi
 
# Make sure we’re using the latest Homebrew.
brew update
 
# Upgrade any already-installed formulae.
brew upgrade --all
 
# Add some casks
brew tap caskroom/cask
brew tap homebrew/dupes
brew services list

formulas=(
    # flags should pass through the the `brew list check`
    'coreutils'
    'macvim --with-override-system-vim'
    ack
    bash
    bash-git-prompt
    diff-so-fancy
    fzf
    git
    gpg
    gpg-agent
    'grep --with-default-names'
    highlight
    hub
    httpie
    jq
    karabiner
    keybase
    nano
    neovim/neovim/neovim
    reattach-to-user-namespace
    ripgrep
    seil
    the_silver_searcher
    tmux
    tree
    unison
    wget
    z
    zsh
)

for formula in "${formulas[@]}"; do
    if brew list "$formula" > /dev/null 2>&1; then
        echo "$formula already installed... skipping."
    else
        brew install $formula
    fi
done

# Development tools
gem install wbench
 
# Cleanup
brew cleanup
rm -f -r /Library/Caches/Homebrew/*

#upgrade bash shell
echo /usr/local/bin/bash | sudo tee -a /etc/shells
chsh -s /usr/local/bin/bash
 
echo "All done! Phew!"

