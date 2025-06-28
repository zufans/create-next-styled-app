#!/bin/bash
# createNewRepo.sh
createNewRepo(){
    repoList=("$@")
    repositoryName=""
    error=false
    while true ; do
        read -p "Repository Name: " repositoryName
        for repo in $repoList; do
            if [ "$repositoryName" == "$repo" ]; then
                echo "Error: There is already repository called $repositoryName"
                error=true
                break
            fi
        done
        if [ $error == false ]; then
            break
        fi

    done
    echo "$repositoryName"
}






export -f createNewRepo