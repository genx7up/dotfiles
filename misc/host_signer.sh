#!/bin/bash
set -e

if [[ ${@: -1} == '--debug' ]];then
	set -x
fi

DOMAIN=nclans.net
VAULT_HTTPS="https://volt.nclans.net"
VTOKEN=$1

######################## Run sudo
[ `whoami` = root ] || exec sudo -E -u root $0 $@
######################## Run sudo

function curlx()
{
	# get output, append HTTP status code in separate line, discard error message
	OUT=$( curl -qSfsw '\n%{http_code}' $2 "$1") 2>/dev/null

	# get exit code
	RET=$?

	if [[ $RET -ne 0 ]] ; then
	    # if error exit code, print exit code
	    echo "Error $RET"

	    # print HTTP error
	    echo "HTTP Error: $(echo "$OUT" | tail -n1 )"
	else
	    # otherwise print last line of output, i.e. HTTP status code
	    #echo "Success, HTTP status is:"
	    HTTP_CODE=$(echo "$OUT" | tail -n1)

	    # and print all but the last line, i.e. the regular response
	    #echo "Response is:"
		N=1
	    OUT=$(echo "$OUT" | sed -n -e ':a' -e "1,$N!{P;N;D;};N;ba")
	fi
}

#unwrap token
curlx "$VAULT_HTTPS/unwrap" "-H X-Vault-Token:$VTOKEN"
VTOKEN=$OUT

# sign host keys
IDENTITY="$(hostname --fqdn) host key"
EXT_IP=$(curl -sS http://checkip.amazonaws.com)
HOSTNAMES="$(hostname),$(hostname --fqdn),$(hostname --fqdn).$DOMAIN,$EXT_IP,$(hostname -I|tr ' ' ',')"

for i in /etc/ssh/ssh_host_*_key.pub; do
	curlx "$VAULT_HTTPS/sign_hostkey?i=$IDENTITY&n=$HOSTNAMES" "-H X-Vault-Token:$VTOKEN -X POST -H Content-Type:text/xml --data @$i"
	CERT_FILE=$(echo $i | sed s/\.pub$/-cert.pub/)
	echo $OUT > $CERT_FILE
	echo "HostCertificate $CERT_FILE" >> /etc/ssh/sshd_config
done

# prepare host for receving connections
curlx "$VAULT_HTTPS/get_userca" "-H X-Vault-Token:$VTOKEN"
echo $OUT > /etc/ssh/user_ca.pub
echo "TrustedUserCAKeys /etc/ssh/user_ca.pub" >> /etc/ssh/sshd_config

mkdir -p /etc/ssh/auth_principals
echo "AuthorizedPrincipalsFile /etc/ssh/auth_principals/%u" >> /etc/ssh/sshd_config
echo "X11Forwarding yes" >> /etc/ssh/sshd_config
echo "X11UseLocalhost no" >> /etc/ssh/sshd_config
service sshd restart

# allow root user
echo -e 'root-dev\nroot-everywhere' > /etc/ssh/auth_principals/root

# create and allow default keyuser with sudo perms
touch /etc/sudoers.d/99-keyuser-rules
for i in {01..03}; do
useradd "user$i"
passwd -l "user$i"
echo "user$i ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/99-keyuser-rules
done

# allow existing users
for user in $(
getent passwd |
awk 'NR==FNR { if ($1 ~ /^UID_(MIN|MAX)$/) m[$1] = $2; next }
{ split ($0, a, /:/);
  if (a[3] >= m["UID_MIN"] && a[3] <= m["UID_MAX"] && a[7] !~ /(false|nologin)$/)
    print a[1] }' /etc/login.defs -); do

    	echo -e 'root-dev\nroot-everywhere' > /etc/ssh/auth_principals/$user
done

# Client setup
curl -sSL https://raw.githubusercontent.com/genx7up/dotfiles/master/misc/volt.sh -o /usr/local/bin/volt.sh
echo 'function volt() { bash /usr/local/bin/volt.sh $@ && source /usr/local/bin/volt.sh load; }' >> /etc/profile
echo 'if [[ -f /usr/local/bin/volt.sh ]]; then source /usr/local/bin/volt.sh load; fi' >> /etc/profile

# IDE bootstrap
echo "bash <(curl -sSL https://raw.githubusercontent.com/genx7up/dotfiles/master/bootstrap.sh)" > /usr/local/bin/idesync
chmod +x /usr/local/bin/idesync
