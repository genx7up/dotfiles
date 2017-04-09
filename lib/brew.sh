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

# Add some casks
brew tap caskroom/cask
brew tap homebrew/dupes
brew services list

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed --with-default-names
# Install Bash 4.
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before
# running `chsh`.
brew install bash
brew tap homebrew/versions
brew install bash-completion2

# Switch to using brew-installed bash as default shell
if ! fgrep -q '/usr/local/bin/bash' /etc/shells; then
  echo 'Will need sudo permissions to update your bash shell (twice)'
  echo '/usr/local/bin/bash' | sudo tee -a /etc/shells;
  chsh -s /usr/local/bin/bash;
fi;

# Install `wget` with IRI support.
brew install wget --with-iri

# Install more recent versions of some macOS tools.
brew install homebrew/dupes/grep
brew install homebrew/dupes/openssh

# Install font tools.
brew tap bramstein/webfonttools
brew install sfnt2woff
brew install sfnt2woff-zopfli
brew install woff2

# Install other useful binaries.
brew install ack
brew install dark-mode
#brew install exiv2
brew install git
brew install git-lfs
brew install imagemagick --with-webp
brew install lua
brew install lynx
brew install p7zip
brew install pigz
brew install pv
brew install rename
brew install rhino
brew install speedtest_cli
brew install ssh-copy-id
brew install testssl
brew install tree
brew install vbindiff
brew install webkit2png
brew install zopfli

formulas=(
    # flags should pass through the the `brew list check`
    'macvim --with-override-system-vim'
    fzf
    gpg
    gpg-agent
    'grep --with-default-names'
    highlight
    hub
    httpie
    jq
    keybase
    nano
    neovim/neovim/neovim
    reattach-to-user-namespace
    ripgrep
    seil
    the_silver_searcher
    tmux
    unison
    z
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

# Install nerd fonts
brew tap caskroom/fonts   
brew cask install font-firacode-nerd-font-mono
brew cask install font-droidsansmono-nerd-font-mono
 
# Cleanup
brew cleanup
rm -f -r /Library/Caches/Homebrew/*

echo "All done! Phew!"

