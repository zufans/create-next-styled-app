#!/bin/bash

checkPackage() {
    package=$1
    if [ -z "$package" ]; then
        echo "Invalid Value"
        exit 1
    fi

    if command -v "$package" &>/dev/null; then
        echo "$package is installed."
    else
        promptMessage="$package is not installed. Would you like to install it?"
        dialog --yesno "$promptMessage" 22 76
        response=$?
        if [ "$response" -eq 0 ]; then
            # 
            if command -v apt-get &>/dev/null; then
                sudo apt-get install -y "$package"
            elif command -v brew &>/dev/null; then
                brew install "$package"
            else
                echo "Error: Unable to install $package. Unsupported package manager."
                exit 1
            fi

            if [ $? -eq 0 ]; then
                echo "$package has been installed successfully."
            else
                echo "Error: $package installation failed."
            fi
            # 
        else
            echo "You chose not to install $package. Exiting."
            exit 1
        fi
    fi
}

# Export the function
export -f checkPackage
