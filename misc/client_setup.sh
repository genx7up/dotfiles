#!/bin/bash
set -e

if [[ ${@: -1} == '--debug' ]];then
	set -x
fi

# Client setup
curl -sSL https://s7k-prod.s3.us-west-2.amazonaws.com/vault/nclans/client/volt.sh -o /usr/local/bin/volt.sh
echo 'function volt() { bash /usr/local/bin/volt.sh $@ && source /usr/local/bin/volt.sh load; }' >> /etc/profile
echo 'if [[ -f /usr/local/bin/volt.sh ]]; then source /usr/local/bin/volt.sh load; fi' >> /etc/profile
#echo 'if [[ ! -d ~/.dotfiles ]]; then /usr/local/bin/idesync && exit; fi' >> /etc/profile

# IDE bootstrap
echo "bash <(curl -sSL https://raw.githubusercontent.com/genx7up/dotfiles/master/bootstrap.sh)" > /usr/local/bin/idesync
chmod +x /usr/local/bin/idesync
