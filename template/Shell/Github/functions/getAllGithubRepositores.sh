#!/bin/sh
# getAllGithubRepositores.sh
function getAllGithubRepositores(){
    repositoryList=()
    tempFile=$(mktemp)
    # gh repo list --limit 100 | awk '{print $1}' > "$tempFile"
    gh repo list | awk '{print $1}' > "$tempFile" # Change to this
    while IFS= read -r line; do
        repoName="${line#*/}"
        repositoryList+=("$repoName")
    done < "$tempFile"
    rm "$tempFile"
    echo "${repositoryList[@]}"
}
export -f getAllGithubRepositores