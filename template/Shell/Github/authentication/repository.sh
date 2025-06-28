#!/bin/bash
# repository.sh

repository(){
    isNewRepository=$1
    personal_access_token_dir=$2
    personal_access_token_file=$(selectAccount "Choose the personal access token file" "$personal_access_token_dir")
    personal_access_token_file_dir="$personal_access_token_dir/$personal_access_token_file"
    # authentication
    githubAuth "$personal_access_token_file_dir"
    repoList="$(getAllGithubRepositores)"
    # read -p "hold " hold
    if [ "$isNewRepository" == "true" ]; then
        # new repository
        newRepo=$(createNewRepo "${repoList[@]}")
        # sendToGitHub "$username" "$newRepo" 0
        # sendToGitHub "$newRepo" 0
        isNewRepo="true"
        sendToGitHub "$newRepo" "$isNewRepo"
    else
        # existing repository
        menu=()
        for repo in $repoList; do
            menu+=("$repo" "")
        done
        cmd=(dialog --menu "Choose Repository: " 22 76 16)
        selection=$("${cmd[@]}" "${menu[@]}" 2>&1 >/dev/tty)
        isNewRepo="false"
        sendToGitHub "$selection" 1
    fi
}
export -f repository
