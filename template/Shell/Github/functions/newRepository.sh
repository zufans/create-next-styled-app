#!/bin/bash
# newRepository.sh
newRepository() {
    personal_access_token_dir=$1
    
    promptMessage="On Github would you like to create a new repository or use an existing repository?  "
    
    menu=("1" "create new repository" "2" "use existing repository")
    cmd=(dialog --menu "$promptMessage " 22 76 16)
    selection=$("${cmd[@]}" "${menu[@]}" 2>&1 >/dev/tty)

    if [ "$selection" -eq 1 ]; then
        # create new repository
        repository "true" "$personal_access_token_dir"
    else
        # use existing repository
        repository "false" "$personal_access_token_dir"
    fi
}
export -f newRepository