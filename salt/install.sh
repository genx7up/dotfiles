#!/bin/bash

set -xe  # Uncomment to enable debugging

pushd salt

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
elif [ "$(uname)" == "Darwin" ]; then
    OS="macOS"
else
    echo "Unsupported operating system"
    exit 1
fi

# CentOS-specific setup
if [[ "$OS" == *"CentOS"* ]]; then
    #Centos specific
    RHEL_REL=`rpm -q --whatprovides redhat-release`
    RELEASEVER=`rpm -q --qf "%{VERSION}" $RHEL_REL`
    BASEARCH=$(uname -m)

    #################################### Setup Salt Repo
    curl -o SALTSTACK-GPG-KEY.pub "https://archive.repo.saltproject.io/yum/redhat/$RELEASEVER/$BASEARCH/latest/SALTSTACK-GPG-KEY.pub"
    rpm --import SALTSTACK-GPG-KEY.pub
    rm -f SALTSTACK-GPG-KEY.pub

    cat > /etc/yum.repos.d/saltstack.repo <<EOF
####################
# Enable SaltStack's package repository
[saltstack-repo]
name=SaltStack repo for Red Hat Enterprise Linux \$releasever
baseurl=https://archive.repo.saltproject.io/yum/redhat/\$releasever/\$basearch/latest
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/SALTSTACK-GPG-KEY.pub
EOF

    #################################### Configure Salt Minion
    yum -y install salt-minion at

# Debian-specific setup
elif [[ "$OS" == *"Debian"* || "$OS" == *"Ubuntu"* ]]; then
    # Update for Debian 12 (bookworm)
    mkdir -p /etc/apt/keyrings
    sudo curl -fsSL -o /etc/apt/keyrings/salt-archive-keyring-2023.gpg https://repo.saltproject.io/salt/py3/debian/12/amd64/SALT-PROJECT-GPG-PUBKEY-2023.gpg
    echo "deb [signed-by=/etc/apt/keyrings/salt-archive-keyring-2023.gpg arch=amd64] https://repo.saltproject.io/salt/py3/debian/12/amd64/latest bookworm main" | sudo tee /etc/apt/sources.list.d/salt.list

    # Update and install Salt
    apt-get update
    apt-get install -y salt-minion at

# macOS-specific setup
elif [ "$OS" == "macOS" ]; then
    # Add check for Apple Silicon
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    # Install Salt
    brew install salt
else
    echo "Unsupported operating system: $OS"
    exit 1
fi

# Common configuration for all OSes
#################################### Configure Salt Minion
mkdir -p /etc/salt
cat > /etc/salt/grains <<EOF
main_role: ide
roles:
  - ide
EOF

# Backup existing minion config
if [ -f /etc/salt/minion ]; then
    cp /etc/salt/minion /etc/salt/minion.bak
fi

# Copy Salt configuration files
mkdir -p /srv/salt /srv/pillar

cp -rpf ./* /srv/salt/
cp -rpf metadata.sls /srv/pillar/
cp -rpf pillar_top.sls /srv/pillar/top.sls

# Apply states
if [ "$OS" != "macOS" ]; then
    salt-call state.apply --local -l debug || true
else
    salt-call --config-dir=/opt/homebrew/etc/salt state.apply --local -l debug || true
fi

echo "Salt installation done"
popd
