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

# Function to install Salt on CentOS
install_salt_centos() {
    RHEL_REL=$(rpm -q --whatprovides redhat-release)
    RELEASEVER=$(rpm -q --qf "%{VERSION}" $RHEL_REL)
    BASEARCH=$(uname -m)

    # Setup Salt Repo
    curl -o SALTSTACK-GPG-KEY.pub "https://archive.repo.saltproject.io/yum/redhat/$RELEASEVER/$BASEARCH/latest/SALTSTACK-GPG-KEY.pub"
    rpm --import SALTSTACK-GPG-KEY.pub
    rm -f SALTSTACK-GPG-KEY.pub

    cat > /etc/yum.repos.d/saltstack.repo <<EOF
[saltstack-repo]
name=SaltStack repo for Red Hat Enterprise Linux \$releasever
baseurl=https://archive.repo.saltproject.io/yum/redhat/\$releasever/\$basearch/latest
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/SALTSTACK-GPG-KEY.pub
EOF

    yum -y install salt-minion at
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
        *"CentOS"*)
            install_salt_centos
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
