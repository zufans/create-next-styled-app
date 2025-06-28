#!/bin/bash
# stageAndCommitFiles.sh
# Function to stage and commit files

stageAndCommitFiles() {
    email=$1
    username=$2
    # Define colors
    GREEN='\033[0;32m'  # Green color
    NC='\033[0m'        # No color
    

    currentBranch=$(git rev-parse --abbrev-ref HEAD)
    # Get the current branch name
    if [ -z "$currentBranch" ]; then
        commitPrompt="Commit message? "
    else
        currentBranch=$(git rev-parse --abbrev-ref HEAD)
        commitPrompt="Current branch ${GREEN}${currentBranch}${NC}: Commit message? "
    fi

    # Prepare the commit prompt with color
    # commitPrompt="Current branch ${GREEN}${currentBranch}${NC}: Commit message? "

    # Commit message validation loop
    while true; do
        # Print the colored prompt message and read user input separately
        printf "$commitPrompt" 
        read commitMessage
        if [ -z "$commitMessage" ]; then
            echo "Commit message cannot be empty. Please provide a commit message."
        else
            break
        fi
    done


    if ! git init; then
        echo "Error initializing repository."
        return 1  # Return failure
    fi

    # Stage files
    if ! git add .; then
        echo "Error staging files."
        return 1  # Return failure
    fi
    echo "Files staged successfully."

    # Commit changes
    if ! git commit -m "$commitMessage"; then
        echo "Commit failed."
        return 1  # Return failure
    fi

    # 
    userName=$(git config --local user.name)
    if [ -z "$userName" ]; then
        # git config --local user.name "$username"
        if ! git config --local user.name "$username"; then
            echo "Error setting user name."
            # return 1  # Return failure
        fi
    fi

    # Check if user.email is set
    userEmail=$(git config --local user.email)
    if [ -z "$userEmail" ]; then
        if ! git config --local user.email "$email"; then
            echo "Error setting user email."
            # return 1  # Return failure
        fi
    fi
    # 
    echo "Commit successful."

    return 0
}

export -f stageAndCommitFiles

