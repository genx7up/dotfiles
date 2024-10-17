#!/bin/bash
set -euo pipefail

# Enable debug mode if '--debug' is the last argument
[[ "${@: -1}" == '--debug' ]] && set -x

# OS-specific configurations
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS configuration
    CMD_sed='sed -E'
    HOME_DIR=$(dscacheutil -q user -a name "$USER" | awk '/^dir:/ {print $2}')
    DATE_CMD='date -jf %Y-%m-%dT%T '
elif [[ "$(uname -s)" == Linux* ]]; then
    # Linux configuration
    CMD_sed='sed -r'
    HOME_DIR=$(getent passwd "$USER" | cut -d: -f6)
    DATE_CMD="date --date="
else
    echo "Unsupported operating system" >&2
    exit 1
fi

# Vault server URL
VAULT_HTTPS="https://volt.nclans.net"

# Function to execute curl commands and handle responses
function curlx()
{
    # Execute curl command, capture output and HTTP status code
    OUT=$( curl -qSfsw '\n%{http_code}' $2 "$1") 2>/dev/null
    RET=$?

    if [[ $RET -ne 0 ]] ; then
        # If curl command failed, print error message and HTTP status code
        echo "Error $RET"
        echo "HTTP Error: $(echo "$OUT" | tail -n1 )"
    else
        # If successful, capture HTTP status code
        HTTP_CODE=$(echo "$OUT" | tail -n1)
        # Remove HTTP status code from output
        N=1
        OUT=$(echo "$OUT" | sed -n -e ':a' -e "1,$N!{P;N;D;};N;ba")
    fi
}

# Function to ensure SSH agent is running and keys are added
function ensureSSHAgent()
{
    set +e
    # Check if SSH agent is running, start if not
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
    
    # Configure ssh-agent
    ssh-add -D &> /dev/null
    # Add valid signed SSH certificates to the agent
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

    # Add git SSH key if it exists
    if [[ -f ~/.ssh/git_rsa ]]; then
        ssh-add ~/.ssh/git_rsa &> /dev/null
    fi
}

# Function to sign an SSH key for a specific role
function sign_key()
{
    ROLE=root-dev
    if [[ $1 != '' && $1 != '--debug' ]];then
        ROLE=$1
    fi

    CERT_NAME=signed_rsa_$ROLE
    if [ ! -f ~/.ssh/$CERT_NAME-cert.pub ]; then
        rm -rf ~/.ssh/$CERT_NAME*
    fi

    # Check if cert has expired
    CERT_EXPIRED=1
    if [ -f ~/.ssh/$CERT_NAME-cert.pub ]; then
        EXPIRY=$(${DATE_CMD}"`ssh-keygen -L -f ~/.ssh/$CERT_NAME-cert.pub  | grep Valid: | awk '{print $5;}'`" +%s)
        diff=$(( $EXPIRY - `date '+%s'` ))
        if [ $diff -gt 0 ]; then
            EXT_IP=$(curl -sS http://checkip.amazonaws.com)
            SRC_IP=$(ssh-keygen -Lf ~/.ssh/$CERT_NAME-cert.pub  | grep source-address | awk '{print $2;}')
            if [[ $EXT_IP == $SRC_IP ]]; then
                CERT_EXPIRED=0
            fi    
        fi
    fi

    # If cert has expired or doesn't exist, create a new one
    if [[ "$CERT_EXPIRED" == "1" ]]; then
        
        echo "Cert not signed or expired. Refershing for role: $ROLE ..."
        
        rm -rf ~/.ssh/$CERT_NAME*
        ssh-keygen -t rsa -b 2048 -f ~/.ssh/$CERT_NAME -q -N ""
        
        bash /usr/local/bin/volt.sh login
        VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)

        curlx "$VAULT_HTTPS/sign_userkey?role=$ROLE" "-H X-Vault-Token:$VTOKEN -X POST -H Content-Type:text/xml --data-binary @$HOME_DIR/.ssh/$CERT_NAME.pub"
        echo "$OUT" > ~/.ssh/$CERT_NAME-cert.pub
        
        # Ensure CertAuth for hosts
        if [[ ! -f ~/.ssh/host_ca.pub ]]; then
            curlx "$VAULT_HTTPS/get_hostca" "-H X-Vault-Token:$VTOKEN"
            echo "$OUT" > ~/.ssh/host_ca.pub
            echo "@cert-authority * $(cat ~/.ssh/host_ca.pub)" >> ~/.ssh/known_hosts
        fi

        echo "Done."
    fi
}

# Main logic based on command-line arguments
if [[ $1 == 'logout' ]]; then
    # Remove Vault token and signed SSH keys
    rm -rf ~/.vault_token
    rm -rf ~/.ssh/signed_rsa*
    echo 'Logged out'

elif [[ $1 == 'login' ]]; then
    # Check if token exists and is not expired
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

    # Perform login process
    curlx "$VAULT_HTTPS/login" "-H X-Vault-Token:$VTOKEN"
    if [[ $HTTP_CODE -eq 201 ]]; then
        printf "\n#######\n"
        printf "Authentication Required: Please paste the following url in your browser. Use your company account to approve. Finally, paste the code that you get.\n\n"
        echo "$OUT"
        printf "\n#######\n\nPaste code here:"
        read CODE < /dev/tty

        if [ ! $CODE ];then
            echo 'Invalid Code. Try again.'
            exit
        fi

        curlx "$VAULT_HTTPS/login?code=$CODE" "-H X-Vault-Token:$VTOKEN"
        echo "$OUT" > ~/.vault_token
        printf "Successfully authenticated to Vault Server.\n"
        bash /usr/local/bin/volt.sh
    fi

elif [[ $1 == 'ct' || $1 == 'callhome_token' ]];then
    # Issue a callhome token
    VTOKEN=0
    if [ -f ~/.vault_token ];then
        VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
    fi

    if [[ "$2" != "" && "$3" != "" ]]; then
        curlx "$VAULT_HTTPS/issue_token_callhome?id=$2&ipv4=$3" "-H X-Vault-Token:$VTOKEN -X POST"
        echo 'Callhome token: ' $OUT
    else
        echo 'No input'
        exit 1
    fi

elif [[ $1 == 'ht' || $1 == 'host_token' ]];then
    # Issue a host token
    VTOKEN=0
    if [ -f ~/.vault_token ];then
        VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
    fi

    curlx "$VAULT_HTTPS/issue_token_host" "-H X-Vault-Token:$VTOKEN"
    echo 'Host token: ' $OUT

elif [[ $1 == 'host_token_raw' ]];then
    # Issue a raw host token
    VTOKEN=0
    if [ -f ~/.vault_token ];then
        VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
    fi

    curlx "$VAULT_HTTPS/issue_token_host_raw" "-H X-Vault-Token:$VTOKEN"
    echo 'Host token: ' $OUT

elif [[ $1 == 'register_device' ]];then
    # Register a device
    VTOKEN=0
    if [ -f ~/.vault_token ];then
        VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
    fi

    if [[ "$2" != "" && "$3" != "" && "$4" != "" ]]; then
        curlx "$VAULT_HTTPS/register_device?id=$2&role=$3&hw_serial=$4" "-H X-Vault-Token:$VTOKEN -X POST"
        echo 'OK'
    else
        echo 'No input'
        exit 1
    fi    

elif [[ $1 == 'unregister_device' ]];then
    # Unregister a device
    VTOKEN=0
    if [ -f ~/.vault_token ];then
        VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
    fi

    if [[ "$2" != "" ]]; then
        curlx "$VAULT_HTTPS/unregister_device?id=$2" "-H X-Vault-Token:$VTOKEN -X POST"
        echo 'OK'
    else
        echo 'No input'
        exit 1
    fi    

elif [[ $1 == 'get' ]];then
    # Get a secret from the vault
    VTOKEN=0
    if [ -f ~/.vault_token ];then
        VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
    fi

    if [[ "$2" != "" ]]; then
        curlx "$VAULT_HTTPS/get_secret?k=$2" "-H X-Vault-Token:$VTOKEN"
        echo "$OUT"
    else
        echo 'No input'
        exit 1
    fi

elif [[ $1 == 'del' || $1 == 'delete' ]];then
    # Delete a secret from the vault
    VTOKEN=0
    if [ -f ~/.vault_token ];then
        VTOKEN=$(cat ~/.vault_token | cut -d',' -f1)
    fi

    if [[ "$2" != "" ]]; then
        curlx "$VAULT_HTTPS/del_secret?k=$2" "-H X-Vault-Token:$VTOKEN"
        echo 'OK'
    else
        echo 'No input'
        exit 1
    fi

elif [[ $1 == 'set' ]];then
    # Set a secret in the vault
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

elif [[ $1 == 'sign' ]];then
    # Sign an SSH key for a specific role
    sign_key $2

elif [[ $1 == 'load' ]];then
    # Ensure SSH agent is running and keys are loaded
    ensureSSHAgent

else
    # Display usage information
    echo 'Usage: volt <option> --debug'
    echo 'Options:'
    echo '"volt login" to authenticate and authorize current host against Vault service'
    echo '"volt logout" to remove authorization from this host'
    echo '"volt get <key>" to get secrets from store'
    echo '"volt set <key> <val>" to store secrets'
    echo '"volt del <key>" to remove secrets from store'
    echo '"volt ht" to generate a short-lived host token'
    echo '"volt sign <role>" to create a new signed public/private key for the requested role (Role argument is optional)'
    echo 'add "--debug" in end to show debug output'
fi
