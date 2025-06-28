#!/bin/bash
publicOrPrivate() {
    local promptMessage="Would you like to create a public or private repository? "
    local menu=("1" "Public" "2" "Private" "3" "Cancel")
    local cmd=(dialog --stdout --menu "$promptMessage" 22 76 16)
    local choices
    # Capture the user's choice and handle UI display
    choices=$("${cmd[@]}" "${menu[@]}" 2>/dev/tty)
    if [ $choices -eq 1 ]; then
        echo "public"
    elif [ $choices -eq 2 ]; then
        echo "private"
    else
        # exit
        echo "Canceled"
        return 1
    fi
}

export -f publicOrPrivate