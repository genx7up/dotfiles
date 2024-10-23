#!/bin/bash
set -e

if [[ ${@: -1} == '--debug' ]]; then
	set -x
fi

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif [ "$(uname)" == "Darwin" ]; then
        echo "macos"
    else
        echo "unsupported"
    fi
}

# Function to install curl
install_curl() {
	case $1 in
		debian)
			sudo apt-get update && sudo apt-get install -y curl
			;;
		redhat)
			sudo yum install -y curl
			;;
		macos)
			if command -v brew >/dev/null 2>&1; then
				brew install curl
			else
				echo "Homebrew not found. Please install Homebrew to proceed."
				exit 1
			fi
			;;
		*)
			echo "Unsupported OS for automatic curl installation."
			exit 1
			;;
	esac
}

# Detect OS
OS=$(detect_os)

# Check if curl is installed, if not, install it
if ! command -v curl >/dev/null 2>&1; then
	echo "curl not found. Installing curl..."
	install_curl $OS
fi

# Client setup
curl -sSL https://s7k-prod.s3.us-west-2.amazonaws.com/vault/nclans/client/volt.sh -o /usr/local/bin/volt.sh
chmod +x /usr/local/bin/volt.sh

# Determine the appropriate profile file
if [[ "$OS" == "macos" ]]; then
	PROFILE_FILE="$HOME/.bash_profile"
else
	PROFILE_FILE="/etc/profile"
fi

# Add volt function and source command to the profile file
echo 'function volt() { bash /usr/local/bin/volt.sh "$@" && source /usr/local/bin/volt.sh load; }' >> "$PROFILE_FILE"
echo 'if [[ -f /usr/local/bin/volt.sh ]]; then source /usr/local/bin/volt.sh load; fi' >> "$PROFILE_FILE"

# IDE bootstrap
echo "bash <(curl -sSL https://raw.githubusercontent.com/genx7up/dotfiles/master/bootstrap.sh)" > /usr/local/bin/idesync
chmod +x /usr/local/bin/idesync

echo "Setup completed successfully."
