#!/bin/bash
# pushTOGitHub.sh
# Function to push code to GitHub

pushTOGitHub() {
    local currentBranch=$(git rev-parse --abbrev-ref HEAD)
    local repositoryName=$(basename -s .git `git config --get remote.origin.url`)
    
    # Define colors
    GREEN='\033[0;32m'  # Green color
    RED='\033[0;31m'    # Red color
    NC='\033[0m'        # No color

    # Check if inside a Git repository
    local isGitInit=$(git rev-parse --is-inside-work-tree 2>/dev/null)
    if [ "$isGitInit" != "true" ]; then
        if ! git init; then
            errorMessage="${GREEN} current branch: $currentBranch. ${RED}Error Initializing repository.${NC}"
            printf "$errorMessage"
            exit 1
        fi
    fi

    # Check if stageAndCommitFiles ran successfully
    if ! stageAndCommitFiles; then
        errorMessage="${GREEN} current branch: $currentBranch. ${RED}Error staging and committing files. Aborting push.${NC}"
        printf "$errorMessage"
        exit 1
    fi

    # Push to the current branch
    if ! git push -u origin "$currentBranch" -f; then
        errorMessage="${GREEN} current branch: $currentBranch. ${RED}Push failed. ${NC}"
        printf "$errorMessage"
        exit 1
    fi

    repositoryMessage="In repository ${GREEN}${repositoryName}${NC}"
    pushedToMessage="Pushed to branch ${GREEN}${currentBranch}${NC}"
    printf "$repositoryMessage\n"
    printf "$pushedToMessage\n"

    return 0
}
export -f pushTOGitHub
