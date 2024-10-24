#!/bin/bash

set -e

# Enable debug mode if '--debug' is the last argument
[[ ${@: -1} == '--debug' ]] && set -x

pushd salt

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$NAME"
    elif [ "$(uname)" == "Darwin" ]; then
        echo "macOS"
    else
        echo "Unsupported operating system"
        exit 1
    fi
}

# Function to install Salt on CentOS/Rocky
install_salt_centos_rocky() {
    # Get release version and base architecture
    RELEASEVER=$(rpm -E %{rhel})
    BASEARCH=$(uname -m)

    # Setup Salt Repo
    sudo rpm --import https://repo.saltproject.io/salt_rc/salt/py3/redhat/9/x86_64/latest/SALT-PROJECT-GPG-PUBKEY-2023.pub
    curl -fsSL https://repo.saltproject.io/salt_rc/salt/py3/redhat/9/x86_64/latest.repo | sudo tee /etc/yum.repos.d/salt.repo

    sudo yum clean expire-cache
    sudo yum -y install salt-minion at
}

# Function to install Salt on Debian/Ubuntu
install_salt_debian_ubuntu() {
    mkdir -p /etc/apt/keyrings
    if [[ "$OS" == *"Ubuntu"* && "$VERSION_ID" == "22.04" ]]; then
        SALT_URL="https://repo.saltproject.io/salt/py3/ubuntu/22.04/amd64"
        DIST="jammy"
    else
        SALT_URL="https://repo.saltproject.io/salt/py3/debian/12/amd64"
        DIST="bookworm"
    fi

    sudo curl -fsSL -o /etc/apt/keyrings/salt-archive-keyring-2023.gpg "${SALT_URL}/SALT-PROJECT-GPG-PUBKEY-2023.gpg"
    echo "deb [signed-by=/etc/apt/keyrings/salt-archive-keyring-2023.gpg arch=amd64] ${SALT_URL}/latest ${DIST} main" | sudo tee /etc/apt/sources.list.d/salt.list

    apt-get update
    apt-get install -y salt-minion at
}

# Function to install Salt on macOS
install_salt_macos() {
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    brew install salt
}

# Function to configure Salt
configure_salt() {
    mkdir -p /etc/salt
    cat > /etc/salt/grains <<EOF
main_role: ide
roles:
  - ide
EOF

    # Backup existing minion config
    [ -f /etc/salt/minion ] && cp /etc/salt/minion /etc/salt/minion.bak

    # Copy Salt configuration files
    mkdir -p /srv/salt /srv/pillar
    cp -rpf ./* /srv/salt/
    cp -rpf metadata.sls /srv/pillar/
    cp -rpf pillar_top.sls /srv/pillar/top.sls
}

# Function to apply Salt states
apply_salt_states() {
    if command -v salt-call &> /dev/null; then
        SALT_CONFIG_DIR="/etc/salt"
        [ "$OS" == "macOS" ] && SALT_CONFIG_DIR="/opt/homebrew/etc/salt"
        salt-call --config-dir="$SALT_CONFIG_DIR" state.apply --local -l debug || true
    fi
}

# Main execution
OS=$(detect_os)

# Install Salt only if not already installed
if ! command -v salt-minion &> /dev/null; then
    case "$OS" in
        *"CentOS"* | *"Rocky"*)
            install_salt_centos_rocky
            ;;
        *"Debian"* | *"Ubuntu"*)
            install_salt_debian_ubuntu
            ;;
        "macOS")
            install_salt_macos
            ;;
        *)
            echo "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
fi

configure_salt
apply_salt_states

echo "Salt installation and configuration completed"
popd
