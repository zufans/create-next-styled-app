#!/bin/bash


checkBrew() {
    if command -v brew &>/dev/null; then
        echo "Homebrew is installed."
    else
        read -p "Homebrew is not installed. Would you like to install it? (yes/no): " answer
        case "$answer" in
            [Yy]*)
                # Install Homebrew
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
                if [ $? -eq 0 ]; then
                    echo "Homebrew has been installed successfully."
                else
                    echo "Error: Homebrew installation failed."
                fi
                ;;
            [Nn]*)
                echo "You chose not to install Homebrew. Exiting."
                exit 1
                ;;
            *)
                echo "Invalid response. Please enter 'yes' or 'no'."
                check_brew # Ask again
                ;;
        esac
    fi
}

# Export the function
export -f checkBrew

# You can now use the 'check_brew' function in other Bash scripts.
