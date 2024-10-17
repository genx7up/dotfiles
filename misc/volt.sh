#!/bin/bash

# Don't use pipefail here. It interferes with interactive logins
set -e
if [ "$(echo "${DEBUG:-}" | tr '[:upper:]' '[:lower:]')" = "true" ]; then set -x; fi

if [[ ${@: -1} == '--debug' ]];then
        set -x
fi

if [ "$(uname)" == "Darwin" ]; then
    # Do something under Mac OS X platform
    CMD_sed='sed -E'
    HOME_DIR=$(dscacheutil -q user -a name $USER | grep dir: | awk '{print $2;}')
    DATE_CMD='date -jf %Y-%m-%dT%T '
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
    CMD_sed='sed -r'
    HOME_DIR=`echo $(getent passwd $USER )| cut -d : -f 6`
    DATE_CMD="date --date="
fi

UNIT_TEST=${UNIT_TEST:-false}
VAULT_HTTPS="${VAULT_URL:-https://volt.nclans.net}"

function curlx()
{
        # get output, append HTTP status code in separate line, discard error message
        if [[ "$UNIT_TEST" == "true" ]]; then
                if [[ "${VAULT_USER:-}" != "" ]]; then
                        INSECURE_FLAG="-k -u ${VAULT_USER:-}:${VAULT_PASS:-}"
                else
                        INSECURE_FLAG="-k"
                fi
        else
                INSECURE_FLAG=""
        fi

        set +x
        OUT=$(curl ${INSECURE_FLAG} -qSsw '\n%{http_code}' $2 "$1") || ( echo $OUT; exit 1 )

        # otherwise print last line of output, i.e. HTTP status code
        #echo "Success, HTTP status is:"
        HTTP_CODE=$(echo "$OUT" | tail -n1)

        if [[ $HTTP_CODE -ge 400 ]] ; then
                # if error exit code, print exit code
                echo "$OUT"
                exit 1
        else
                # and print all but the last line, i.e. the regular response
                #echo "Response is:"
                N=1
                OUT=$(echo "$OUT" | sed -n -e ':a' -e "1,$N!{P;N;D;};N;ba")
        fi
        if [ "$(echo "${DEBUG:-}" | tr '[:upper:]' '[:lower:]')" = "true" ]; then set -x; fi
}

function ensureSSHAgent()
{
        set +e
        if [ ! -r ~/.ssh-agent ]; then
            (umask 066; ssh-agent -t 4000 > ~/.ssh-agent)
        fi
        eval "$(<~/.ssh-agent)" >/dev/null
        ssh-add &>/dev/null
        if [ "$?" == 2 ]; then
            (umask 066; ssh-agent -t 4000 > ~/.ssh-agent)
            eval "$(<~/.ssh-agent)" >/dev/null
            ssh-add
        fi

        #Configure ssh-agent
        ssh-add -D &> /dev/null
        for i in ~/.ssh/signed_rsa*-cert.pub; do
                if [[ -f $i ]]; then
                        CERT_FILE=$(echo $i | sed s/-cert.pub$//)
                        ROLE=$(echo $i | $CMD_sed 's/[^_]+_rsa_(.+)-cert.pub$/\1/g')
                        EXPIRY=$(${DATE_CMD}"`ssh-keygen -Lf $i | grep Valid: | awk '{print $5;}'`" +%s)

                        diff=$(( $EXPIRY - `date '+%s'` ))
                        if [ $diff -gt 0 ]; then
                                ssh-add $CERT_FILE &> /dev/null
                                #echo "!! Added $ROLE cert to ssh-agent"
                        else
                                echo "!! Skipping role $ROLE : Cert Expired $i, remove key or volt sign $ROLE"
                        fi
                fi
        done

        if [[ -f ~/.ssh/git_rsa ]]; then
                ssh-add ~/.ssh/git_rsa &> /dev/null
        fi
}

function sign_key()
{
        # Ensure grepcidr
        [[ `type grepcidr` ]] || yum -y install grepcidr || apt-get -y install grepcidr || brew install grepcidr || ( echo "grepcidr is missing" && exit 1 )

        ROLE=$1
        CERT_NAME=signed_rsa_$ROLE
        if [ ! -f ~/.ssh/$CERT_NAME-cert.pub ]; then
                rm -rf ~/.ssh/$CERT_NAME*
        fi

        # If cert has expired, only then try renewing
        EXT_IP=$(curl -sS http://checkip.amazonaws.com)
        CERT_EXPIRED=1
        if [ -f ~/.ssh/$CERT_NAME-cert.pub ]; then
                EXPIRY=$(${DATE_CMD}"`ssh-keygen -L -f ~/.ssh/$CERT_NAME-cert.pub  | grep Valid: | awk '{print $5;}'`" +%s)
                diff=$(( $EXPIRY - `date '+%s'` ))
                if [ $diff -gt 0 ]; then
                        SRC_IP=$(ssh-keygen -Lf ~/.ssh/$CERT_NAME-cert.pub  | grep source-address | awk '{print $2;}')
                        if [[ $(grepcidr "$SRC_IP" <(echo $EXT_IP) >/dev/null; echo $?) == "0" ]]; then
                                CERT_EXPIRED=0
                        fi
                fi
        fi

        if [[ "$CERT_EXPIRED" == "1" ]]; then

                echo "Cert not signed or expired. Refershing for role: $ROLE ..."

                rm -rf ~/.ssh/$CERT_NAME*
                ssh-keygen -t rsa -b 2048 -f ~/.ssh/$CERT_NAME -q -N ""

                bash $0 login
                VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)

                curlx "$VAULT_HTTPS/sign_userkey?role=$ROLE&ipv4=$EXT_IP" "-H X-Vault-Token:$VTOKEN -X POST -H Content-Type:text/xml --data-binary @$HOME_DIR/.ssh/$CERT_NAME.pub"
                echo "$OUT" > ~/.ssh/$CERT_NAME-cert.pub

                #Ensure CertAuth for hosts
                if [[ ! -f ~/.ssh/host_ca.pub ]]; then
                        curlx "$VAULT_HTTPS/get_hostca" "-H X-Vault-Token:$VTOKEN"
                        echo "$OUT" > ~/.ssh/host_ca.pub
                        echo "@cert-authority * $(cat ~/.ssh/host_ca.pub)" >> ~/.ssh/known_hosts
                fi

                echo "Done."
        fi
}

CMD=${1:-}

if [[ $CMD == 'logout' ]];then
        rm -rf ~/.vault_token
        rm -rf ~/.ssh/signed_rsa*
        echo 'Logged out'

elif [[ $CMD == 'login' ]];then
        EXPIRY=0
        VTOKEN=0
        if [ -f ~/.vault_token ];then
                VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
                EXPIRY=$(cat ~/.vault_token | cut -d',' -f2)
        fi

        diff=$(( $EXPIRY - `date '+%s'` ))
        if [ $diff -gt 0 ]; then
                echo "Token not expired"
                exit
        fi

        curlx "$VAULT_HTTPS/login" "-H X-Vault-Token:$VTOKEN -X POST"
        if [[ $HTTP_CODE -eq 201 ]]; then

                if [ -f "$HOME/.github_patoken" ]; then
                        CODE=$(cat ~/.github_patoken)
                else
                        printf "\nAuthentication Required: Copy/Paste \"Personal Access Token\" from your Github account( https://github.com/settings/tokens ). The token must have \"read:org\" scope.\n\n"
                        printf "### Paste code here :"
                        read CODE < /dev/tty

                        if [ ! $CODE ];then
                                echo 'Invalid Code. Try again.'
                                exit
                        fi

                        printf "\n### Do you want to save token on this private machine to enable auto-auth? (y/n)"
                        read SAVE_TOKEN < /dev/tty

                        if [[ "$SAVE_TOKEN" == "y" || "$SAVE_TOKEN" == "Y" ]]; then
                                echo $CODE > ~/.github_patoken
                        fi
                fi
                printf "\n"

                curlx "$VAULT_HTTPS/login" "-H X-Vault-Token:$VTOKEN -H X-Auth-Token:$CODE -X POST" || ( rm -f ~/.github_patoken && exit 1 )
                echo "$OUT" > ~/.vault_token
                #printf "token: $HTTP_CODE,$OUT\n"
                printf "Successfully authenticated to Vault Server.\n\n"
                bash $0
        fi

elif [[ $CMD == 'ct' || $CMD == 'callhome_token' ]];then
        VTOKEN=0
        if [ -f ~/.vault_token ];then
                VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
        fi

        if [[ "${2:-}" != "" && "${3:-}" != "" ]]; then
                curlx "$VAULT_HTTPS/issue_token_callhome?userid=$2&ipv4=$3" "-H X-Vault-Token:$VTOKEN -X POST"
                echo $OUT
        else
                echo 'No input'
                exit 1
        fi

elif [[ $CMD == 'ht' || $CMD == 'host_token' ]];then
        VTOKEN=0
        if [ -f ~/.vault_token ];then
                VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
        fi

        curlx "$VAULT_HTTPS/issue_token_host" "-H X-Vault-Token:$VTOKEN"
        echo $OUT

elif [[ $CMD == 'host_token_raw' ]];then
        VTOKEN=0
        if [ -f ~/.vault_token ];then
                VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
        fi

        curlx "$VAULT_HTTPS/issue_token_host_raw" "-H X-Vault-Token:$VTOKEN"
        echo $OUT

elif [[ $CMD == 'register_device' ]];then
        VTOKEN=0
        if [ -f ~/.vault_token ];then
                VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
        fi

        if [[ "${2:-}" != "" && "${3:-}" != "" && "${4:-}" != "" ]]; then
                curlx "$VAULT_HTTPS/register_device?secret_id=$2&role=$3&hw_serial=$4" "-H X-Vault-Token:$VTOKEN -X POST"
                echo 'OK'
        else
                echo 'No input'
                exit 1
        fi

elif [[ $CMD == 'unregister_device' ]];then
        VTOKEN=0
        if [ -f ~/.vault_token ];then
                VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
        fi

        if [[ ${2:-} != '' && ${2:-} != '--debug' ]]; then
                curlx "$VAULT_HTTPS/unregister_device?secret_id=$2" "-H X-Vault-Token:$VTOKEN -X POST"
                echo 'OK'
        else
                echo 'No input'
                exit 1
        fi

elif [[ $CMD == 'get' ]];then
        VTOKEN=0
        if [ -f ~/.vault_token ];then
                VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
        fi

        if [[ ${2:-} != '' && ${2:-} != '--debug' ]]; then
                curlx "$VAULT_HTTPS/get_secret?k=$2" "-H X-Vault-Token:$VTOKEN"
                echo "$OUT"
        else
                echo 'No input'
                exit 1
        fi

elif [[ $CMD == 'del' || $CMD == 'delete' ]];then
        VTOKEN=0
        if [ -f ~/.vault_token ];then
                VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
        fi

        if [[ ${2:-} != '' && ${2:-} != '--debug' ]]; then
                curlx "$VAULT_HTTPS/del_secret?k=$2" "-H X-Vault-Token:$VTOKEN"
                echo 'OK'
        else
                echo 'No input'
                exit 1
        fi

elif [[ $CMD == 'set' ]];then
        VTOKEN=0
        if [ -f ~/.vault_token ];then
                VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
        fi

        if [[ "$2" != "" && "$3" != "" ]]; then
                curlx "$VAULT_HTTPS/set_secret?k=$2" "-H X-Vault-Token:$VTOKEN -X POST -H Content-Type:text/xml --data-binary $3"
                echo 'OK'
        else
                echo 'No input'
                exit 1
        fi

elif [[ $CMD == 'get-team' ]];then
        VTOKEN=0
        if [ -f ~/.vault_token ];then
                VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
        fi

        if [[ ${2:-} != '' && ${2:-} != '--debug' ]]; then
                curlx "$VAULT_HTTPS/get_team?k=$2" "-H X-Vault-Token:$VTOKEN"
                echo "$OUT"
        else
                echo 'No input'
                exit 1
        fi

elif [[ $CMD == 'del-team' ]];then
        VTOKEN=0
        if [ -f ~/.vault_token ];then
                VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
        fi

        if [[ ${2:-} != '' && ${2:-} != '--debug' ]]; then
                curlx "$VAULT_HTTPS/del_team?k=$2" "-H X-Vault-Token:$VTOKEN"
                echo 'OK'
        else
                echo 'No input'
                exit 1
        fi

elif [[ $CMD == 'set-team' ]];then
        VTOKEN=0
        if [ -f ~/.vault_token ];then
                VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
        fi

        if [[ "$2" != "" && "$3" != "" ]]; then
                curlx "$VAULT_HTTPS/set_team?k=$2" "-H X-Vault-Token:$VTOKEN -X POST -H Content-Type:text/xml --data-binary $3"
                echo 'OK'
        else
                echo 'No input'
                exit 1
        fi

elif [[ $CMD == 'sign' ]];then
        ROLE=root-dev
        if [[ ${2:-} != '' && ${2:-} != '--debug' ]]; then
                ROLE=$2
        fi
        sign_key $ROLE

elif [[ $CMD == 'load' ]];then
        ensureSSHAgent

else
        echo 'Usage: volt <option> --debug'
        echo 'Options:'
        echo '"volt login" to authenticate and authorize current host against Vault service'
        echo '"volt logout" to remove authorization from this host'
        echo '"volt get <key>" to get secrets from personal vault'
        echo '"volt set <key> <val>" to store secrets into personal vault'
        echo '"volt del <key>" to remove secrets from personal vault'
        echo '"volt get-team <key>" to get secrets from shared team vault'
        echo '"volt set-team <key> <val>" to store secrets into shared team vault'
        echo '"volt del-team <key>" to remove secrets from shared team vault'
        echo '"volt ht" to generate a short-lived host token'
        echo '"volt sign <role>" to create a new signed public/private key for the requested role (Role argument is optional)'
        echo 'add "--debug" in end to show debug output'
fi
