#!/bin/bash

personal_access_token="../../../.ssh/personal_access_token"
CYAN="\x1b[1;36m"
WHITE="\x1b[0;37m"

loopOnObject(){
    count=$1
    account=$2
    keys=$(echo "$account" | jq -r 'keys[]')
    values=$(echo "$account" | jq -r '.[]')
    keysArray=($keys)
    valuesArray=($values)
    length=${#keysArray[@]}
    for ((i=0; i<$length; i++)); do
        key=${keysArray[$i]}
        value=${valuesArray[$i]}
        if [ $i -eq $count ]; then
            echo "${CYAN}$key${WHITE}"
        else
            echo "${WHITE}$key${WHITE}"
        fi
    done
}

getPersonalTokenFile(){
    if ! [ -d $personal_access_token ]; then
        echo "$personal_access_token directory does not exist "
        return 1
    fi
    personalTokenFile=""
    account=$(jq -n '{}')
    for file in $personal_access_token/*; do
        filename=$(basename "$file")
        if [[ $filename == *"_personal_access_token.txt" ]]; then
            key=${filename%%_*}
            account=$(echo "$account" | jq --arg key "$key" --arg value "$filename" '. + {($key): $value}')
        fi
    done

    count=0
    keys=$(echo "$account" | jq -r 'keys[]')
    values=$(echo "$account" | jq -r '.[]')
    keysArray=($keys)
    valuesArray=($values)
    length=${#keysArray[@]}
    while true; do
        clear
        loopOnObject $count "$account"
        read -s -n 3 key
        case "$key" in
            $'\x1b[A')
                if [ $count -gt 0 ]; then
                    count=$((count - 1))
                fi
            ;;
            $'\x1b[B')
                if [ $count -lt $((length - 1)) ]; then
                    count=$((count + 1))
                fi
            ;;
            "")
                value=${valuesArray[count]};
                personalTokenFile="$personal_access_token/$value"
                echo "$personalTokenFile"
                break
            ;;
        esac
        # break;
    done
    echo "Personal Token File: $personalTokenFile"
}
# getPersonalTokenFile(){
#     echo "Function getPersonalTokenFile is executing." # -------
# }
export -f getPersonalTokenFile