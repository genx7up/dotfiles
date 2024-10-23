#!/usr/bin/env bash

# Function to install a formula or cask
install_brew_package() {
    local package=$1
    local type=$2
    if ! brew list $type "$package" &> /dev/null; then
        brew install $type "$package"
    else
        echo "$package already installed... skipping."
    fi
}

# Function to install multiple packages
install_packages() {
    local type=$1
    shift
    local packages=("$@")
    for package in "${packages[@]}"; do
        install_brew_package "$package" "$type"
    done
}

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Update and upgrade Homebrew
brew update
brew upgrade

# Install GNU core utilities and Bash
brew install coreutils bash bash-completion2

# Switch to brew-installed bash as default shell
if ! grep -q '/usr/local/bin/bash' /etc/shells; then
    echo "Updating default shell to brew-installed bash (requires sudo)..."
    echo '/usr/local/bin/bash' | sudo tee -a /etc/shells
    chsh -s /usr/local/bin/bash
fi

# Install font tools
brew tap bramstein/webfonttools
install_packages "" sfnt2woff sfnt2woff-zopfli woff2

# Install formulas
formulas=(
    ack
    chromedriver
    dark-mode
    findutils
    fzf
    gh
    git
    git-lfs
    gpg
    gpg-agent
    gnu-sed
    grep
    highlight
    hub
    httpie
    imagemagick
    jq
    lua
    macvim
    mas
    moreutils
    nano
    neovim
    npm
    p7zip
    pigz
    pv
    reattach-to-user-namespace
    rename
    rhino
    ripgrep
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
    wget
    yamllint
    z
    zopfli
)
install_packages "" "${formulas[@]}"

# Install fonts
brew tap homebrew/cask-fonts
fonts=(
    font-firacode-nerd-font-mono
    font-droidsansmono-nerd-font-mono
)
install_packages "--cask" "${fonts[@]}"

# Install Keybase
install_brew_package "keybase" "--cask"

# Cleanup
brew cleanup

echo "Software update complete."
