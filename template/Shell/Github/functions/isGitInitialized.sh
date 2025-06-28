#!/bin/bash

# Function to check Git initialization and authentication
isGitInitialized() {
    local personal_access_token_dir=$1
    local auth_status=$(gh auth status)
    local isGitInit=$(git rev-parse --is-inside-work-tree 2>/dev/null)

    # Check if Git is initialized and authenticated with GitHub
    if [ "$isGitInit" == "true" ] && [[ $auth_status == *"Logged in"* ]]; then
        # Authenticate with GitHub and push
        pushTOGitHub || return 1
    elif [[ $auth_status != *"Logged in"* ]]; then
        echo "Not authenticated with GitHub."
        # Select the token file and authenticate with GitHub
        local select_token_file=$(selectAccount "Choose the personal access token file" "$personal_access_token_dir")
        githubAuth "$select_token_file" || return 1

        # Push changes to GitHub after authentication
        pushTOGitHub || return 1
    else
        # If Git is not initialized, prompt to initialize
        dialog --yesno "Project not initialized with git. Would you like to initialize with git?" 22 76
        local response=$?
        if [ "$response" -eq 0 ]; then
            newRepository "$personal_access_token_dir" || return 1
        else
            echo "Git initialization aborted."
            return 1
        fi
    fi
    return 0
}


export -f isGitInitialized