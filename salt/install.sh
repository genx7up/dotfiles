#!/bin/bash
set -x
set +e

pushd salt

IS_CENTOS=$(gawk -F= '/^NAME/{print $2}' /etc/os-release | grep -i centos -c)

if [ "$IS_CENTOS" = 1 ]; then

  #Centos specific
  RHEL_REL=`rpm -q --whatprovides redhat-release`
  RELEASEVER=`rpm -q --qf "%{VERSION}" $RHEL_REL`
  BASEARCH=$(uname -m)

  #################################### Setup Salt Repo
  curl -o SALTSTACK-GPG-KEY.pub "https://repo.saltstack.com/yum/redhat/$RELEASEVER/$BASEARCH/latest/SALTSTACK-GPG-KEY.pub"
  rpm --import SALTSTACK-GPG-KEY.pub
  rm -f SALTSTACK-GPG-KEY.pub

  cat > /etc/yum.repos.d/saltstack.repo <<EOF
####################
# Enable SaltStack's package repository
[saltstack-repo]
name=SaltStack repo for Red Hat Enterprise Linux \$releasever
baseurl=https://repo.saltstack.com/yum/redhat/\$releasever/\$basearch/latest
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/SALTSTACK-GPG-KEY.pub
EOF

  #################################### Configure Salt Minion
  yum -y install salt-minion at

  ### Add Grains file
  mkdir -p /etc/salt
  cat > /etc/salt/grains <<EOF
main_role: ide
roles:
  - ide
EOF

fi

\cp /etc/salt/minion /etc/salt/minion.bak
#\cp minion_base /etc/salt/minion

mkdir -p /srv/salt /srv/pillar

\cp -rpf ./* /srv/salt/
\cp -rpf metadata.sls /srv/pillar/
\cp -rpf pillar_top.sls /srv/pillar/top.sls

# Apply states
salt-call state.apply --local -l debug

set -e
popd
