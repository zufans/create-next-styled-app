#!/bin/sh
newLine=$(echo $'\n> ')

function grapLocalSSHconfigNames(){
    sshConfig=()
    while IFS= read -r line
    do
        if [[ $line == Host* ]]
        then
            sshConfig+=("$(echo $line | cut -d' ' -f2)")
        fi
    done < ~/.ssh/config

    echo "${sshConfig[@]}"
}

export -f grapLocalSSHconfigNames