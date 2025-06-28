#!/bin/sh
# selectAccount.sh
selectAccount() {
    promptMessage=$1
    fileDirectory=$2
    if [[ -z "$promptMessage" || -z "$fileDirectory" ]]; then
        echo "Both promptMessage and fileDirectory inputs must be provided."
        return 1
    fi
    # fileDirectory=~/$fileDirectory
    if [[ ! -d "$fileDirectory" ]]; then
        echo "The directory $fileDirectory does not exist."
        return 1
    fi
    account=$(jq -n '{}')
    for file in $fileDirectory/*; do
        filename=$(basename "$file")
        if [[ $filename == *"_personal_access_token.txt" ]]; then
            key=${filename%%_*}
            account=$(echo "$account" | jq --arg key "$key" --arg value "$filename" '. + {($key): $value}')
        fi
    done

    keys=$(echo "$account" | jq -r 'keys[]')
    values=$(echo "$account" | jq -r '.[]')
    keysArray=($keys)
    valuesArray=($values)
    length=${#keysArray[@]}
    menu=()
    for ((i=0; i<$length; i++)); do
        key=${keysArray[$i]}
        value=${valuesArray[$i]}
        # menu+=("$key" "$value")
        menu+=("$key" "")
    done
    cmd=(dialog --menu "$promptMessage" 22 76 16)
    selection=$("${cmd[@]}" "${menu[@]}" 2>&1 >/dev/tty)
    value=$(echo "$account" | jq -r ".$selection")
    echo "$value"
}
export -f selectAccount

