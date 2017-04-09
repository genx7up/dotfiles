#!/bin/bash
set -e

if [[ ${@: -1} == '--debug' ]];then
	set -x
fi

# Client setup
curl -sSL https://raw.githubusercontent.com/genx7up/dotfiles/master/misc/volt.sh -o /usr/local/bin/volt.sh
echo 'function volt() { bash /usr/local/bin/volt.sh $@ && source /usr/local/bin/volt.sh load; }' >> /etc/profile
echo 'if [[ -f /usr/local/bin/volt.sh ]]; then source /usr/local/bin/volt.sh load; fi' >> /etc/profile

# IDE bootstrap
echo "bash <(curl -sSL https://raw.githubusercontent.com/genx7up/dotfiles/master/bootstrap.sh)" > /usr/local/bin/idesync
chmod +x /usr/local/bin/idesync
