#!/usr/bin/env bash

# Check for Homebrew
if test ! $(which brew)
then
  echo "  Installing Homebrew for you."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" > /tmp/homebrew-install.log
fi

# Install command-line tools using Homebrew.

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Remove deprecated taps and commands
# brew tap caskroom/cask  # Remove this line
# brew tap homebrew/dupes  # Remove this line
# brew tap homebrew/versions  # Remove this line

# Update deprecated formula options
brew install grep
brew install gnu-sed
brew install imagemagick
brew install macvim

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils

# Install Bash 4.
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before
# running `chsh`.
brew install bash
brew install bash-completion2

# Switch to using brew-installed bash as default shell
if ! fgrep -q '/usr/local/bin/bash' /etc/shells; then
  echo 'Will need sudo permissions to update your bash shell (twice)'
  echo '/usr/local/bin/bash' | sudo tee -a /etc/shells;
  chsh -s /usr/local/bin/bash;
fi;

# Install font tools.
brew tap bramstein/webfonttools
brew install sfnt2woff
brew install sfnt2woff-zopfli
brew install woff2

formulas=(
    ack
    chromedriver
    dark-mode
    findutils
    fzf
    git
    git-lfs
    gpg
    gpg-agent
    'gnu-sed --with-default-names'
    'grep --with-default-names'
    highlight
    hub
    httpie
    'imagemagick --with-webp'
    jq
    lua
    'macvim --with-override-system-vim'
    mas
    moreutils
    nano
    npm
    neovim/neovim/neovim
    p7zip
    pigz
    pv
    reattach-to-user-namespace
    rename
    ripgrep
    rhino
    ruby
    shellcheck
    speedtest_cli
    ssh-copy-id
    testssl
    the_silver_searcher
    tmux
    tree
    unison
    vbindiff
    webkit2png
    'wget --with-iri'
    yamllint
    z
    zopfli
)

for formula in "${formulas[@]}"; do
    if brew list "$formula" > /dev/null 2>&1; then
        echo "$formula already installed... skipping."
    else
        brew install $formula
    fi
done

# Install nerd fonts
brew tap caskroom/fonts
brew install --cask font-firacode-nerd-font-mono
brew install --cask font-droidsansmono-nerd-font-mono

brew install --cask keybase

# Cleanup
brew cleanup

echo "Software updated ..."
