#!/bin/bash
set -e

if [[ ${@: -1} == '--debug' ]]; then
	set -x
fi

# Function to detect OS family
detect_os() {
    if [ "$(uname)" == "Darwin" ]; then
        echo "macos"
    elif [ -f /etc/os-release ]; then
        . /etc/os-release
        # Normalize to OS family
        case "$ID" in
            debian|ubuntu|linuxmint|pop)
                echo "debian"
                ;;
            rhel|centos|fedora|rocky|almalinux)
                echo "redhat"
                ;;
            *)
                # Check ID_LIKE for derivatives
                if [[ "$ID_LIKE" == *"debian"* ]]; then
                    echo "debian"
                elif [[ "$ID_LIKE" == *"rhel"* ]] || [[ "$ID_LIKE" == *"fedora"* ]]; then
                    echo "redhat"
                else
                    echo "unsupported"
                fi
                ;;
        esac
    else
        echo "unsupported"
    fi
}

# Function to install curl
install_curl() {
	case $1 in
		debian)
			apt-get update && apt-get install -y curl
			;;
		redhat)
			# Use dnf if available (RHEL 8+/CentOS 8+), otherwise yum
			if command -v dnf >/dev/null 2>&1; then
				dnf install -y curl
			else
				yum install -y curl
			fi
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

if [[ "$OS" == "unsupported" ]]; then
	echo "Error: Unsupported operating system"
	exit 1
fi

# Check if curl is installed, if not, install it
if ! command -v curl >/dev/null 2>&1; then
	echo "curl not found. Installing curl..."
	# Check if we need sudo
	if [ "$EUID" -ne 0 ]; then
		if command -v sudo >/dev/null 2>&1; then
			echo "Note: Installing curl requires root privileges"
			sudo bash -c "$(declare -f install_curl); install_curl $OS"
		else
			echo "Error: This script requires sudo to install curl. Please install curl manually or run as root."
			exit 1
		fi
	else
		install_curl $OS
	fi
fi

# Client setup - check for privileges
if [ "$EUID" -ne 0 ]; then
	if command -v sudo >/dev/null 2>&1; then
		echo "Note: Installing to /usr/local/bin requires root privileges"
		SUDO_CMD="sudo"
	else
		echo "Error: This script requires sudo privileges. Please run as root."
		exit 1
	fi
else
	SUDO_CMD=""
fi

$SUDO_CMD curl -sSL https://s7k-prod.s3.us-west-2.amazonaws.com/vault/nclans/client/volt.sh -o /usr/local/bin/volt.sh || {
	echo "Error: Failed to download volt.sh"
	exit 1
}
$SUDO_CMD chmod +x /usr/local/bin/volt.sh

# Determine the appropriate profile file
if [[ "$OS" == "macos" ]]; then
	# Check which shell is default
	if [[ "$SHELL" == *"zsh"* ]] || [[ -f "$HOME/.zshrc" ]]; then
		PROFILE_FILE="$HOME/.zshrc"
	else
		PROFILE_FILE="$HOME/.bash_profile"
	fi
	SUDO_PROFILE=""
else
	PROFILE_FILE="/etc/profile"
	SUDO_PROFILE="$SUDO_CMD"
fi

# Add volt function and source command to the profile file (check for duplicates)
VOLT_FUNCTION='function volt() { bash /usr/local/bin/volt.sh "$@" && source /usr/local/bin/volt.sh load; }'
VOLT_SOURCE='if [[ -f /usr/local/bin/volt.sh ]]; then source /usr/local/bin/volt.sh load; fi'

if ! grep -qF "volt.sh" "$PROFILE_FILE" 2>/dev/null; then
	echo "$VOLT_FUNCTION" | $SUDO_PROFILE tee -a "$PROFILE_FILE" > /dev/null
	echo "$VOLT_SOURCE" | $SUDO_PROFILE tee -a "$PROFILE_FILE" > /dev/null
	echo "Added volt configuration to $PROFILE_FILE"
else
	echo "volt configuration already exists in $PROFILE_FILE"
fi

# IDE bootstrap
echo "bash <(curl -sSL https://raw.githubusercontent.com/genx7up/dotfiles/master/bootstrap.sh)" | $SUDO_CMD tee /usr/local/bin/idesync > /dev/null || {
	echo "Error: Failed to create idesync script"
	exit 1
}
$SUDO_CMD chmod +x /usr/local/bin/idesync

echo "Setup completed successfully."
echo "Please run 'source $PROFILE_FILE' or restart your shell to use volt command."
