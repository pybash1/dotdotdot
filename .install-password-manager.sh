#!/bin/sh

# Exit immediately if brew, op, and age are already in PATH
if type brew >/dev/null 2>&1 && type op >/dev/null 2>&1 && type age >/dev/null 2>&1; then
    exit 0
fi

case "$(uname -s)" in
Darwin)
    # 1. Install Homebrew if missing
    if ! type brew >/dev/null 2>&1; then
        echo "🍺 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Make brew available in this shell script
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    # 2. Install 1Password CLI next
    if ! type op >/dev/null 2>&1; then
        echo "🔐 Installing 1Password CLI..."
        brew install --cask 1password-cli
        # Prompt user to authenticate if op isn't signed in
        echo "⚠️  Please open the 1Password app, go to Settings -> Developer, and enable 'Integrate with 1Password CLI'."
    fi

    # 3. Setup age for decryption
    if ! type age >/dev/null 2>&1; then
        echo "🔑 Installing age..."
        brew install age
    fi
    ;;
Linux)
    # Add Linux package manager commands here if needed later
    ;;
*)
    echo "unsupported OS"
    exit 1
    ;;
esac
