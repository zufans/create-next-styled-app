#!/bin/bash


checkDialog(){
    if command -v dialog &>/dev/null; then
        echo "dialog is installed."
    else
        CYAN="\x1b[1;36m"
        WHITE="\x1b[0;37m"
        selected="Yes"
        leftKey="D"
        rightKey="C"
        enterKey=""
        promptMessage="The dialog package is not installed. Would you like to install dialog? "
        while true; do
            clear
            if [ "$selected" == "Yes" ]; then
                echo "$promptMessage ${CYAN}Yes${WHITE} / No"
            else
                echo "$promptMessage Yes${WHITE} / ${CYAN}No${WHITE}"
            fi
            read -s -n 1 key
            case "$key" in
                "$leftKey")
                    selected="Yes" 
                    ;;
                "$rightKey")
                    selected="No" 
                    ;;
                "$enterKey")
                    clear
                    if [ "$selected" == "Yes" ]; then
                        if command -v apt-get &>/dev/null; then
                            sudo apt-get install -y dialog
                        elif command -v brew &>/dev/null; then
                            brew install dialog
                        else
                            echo "Error: Unable to install dialog. Unsupported package manager."
                            exit 1
                        fi

                        # 
                        if [ $? -eq 0 ]; then
                            echo "dialog has been installed successfully."
                        else
                            echo "Error: dialog installation failed."
                        fi
                        # 
                    else
                        echo "You chose not to install dialog. Exiting."
                        exit 1
                    fi
                    break 
                    ;;
            esac
        done
    fi
}

export -f checkDialog