#!/bin/bash

initAddCommit(){
    commitMessage=$1
    
    # Check if commit message is provided
    if [ -n "$commitMessage" ]; then
        # If commit message is NOT empty (note the -n flag)
        if ! git commit -m "$commitMessage"; then
            echo "Commit failed."
            return 1  # Return failure
        else
            echo "Commit successful."
        fi
        return 0
    else
        # If commit message is empty, do init and add
        if ! git init; then
            echo "Error initializing repository."
            return 1  # Return failure
        else
            echo "Repository initialized."
        fi

        if ! git add .; then
            echo "Error staging files."
            return 1  # Return failure
        else
            echo "Files staged for commit."
        fi
    fi
}
sendToGitHub(){
    # username=$1
    repoName=$1
    newRepo=$2

    username=$(gh api user | jq -r '.login')
    if [ -z "$username" ]; then
        echo "Error: Could not retrieve username from GitHub API."
        return 1  # Return failure
    fi

    echo "newRepo: $newRepo"
    if [ "$newRepo" == "true" ]; then
        echo "repoName: $repoName"
        publicPrivate=$(publicOrPrivate)
        initAddCommit
        # git init
        # git add .
        read -p "commit message? " commitMessage
        initAddCommit "$commitMessage"
        # git commit -m "$commitMessage"

        if [ "$publicPrivate" == "public" ]; then
            # gh repo create $repoName --public --source=. --remote=origin  --push
            
            if ! gh repo create $repoName --public --source=. --remote=origin  --push; then
                echo "Error creating repository."
                return 1  # Return failure
            else
                echo "Repository created successfully."
            fi

            # initAddCommit
            # read -p "commit message? " commitMessage
            # initAddCommit "$commitMessage"
        else

            if ! gh repo create $repoName --private --source=. --remote=origin  --push; then
                echo "Error creating repository."
                return 1  # Return failure
            fi        


            # gh repo create $repoName --private --source=. --remote=origin  --push


        fi
        
        emailList=$(gh api user/public_emails)
        email=$(echo "$emailList" | jq -r '.[] | select(.primary==true) | .email')
        # username=$(gh api user | jq -r '.login')
        name=$(gh api user | jq -r '.name')
        echo "email: $email"
        # git config --local user.email "$email"
        # git config --local user.name "$name"
        # git remote add origin git@$username:$username/$repoName.git

        username=$(git config --local user.name)
        if [ -z "$username" ]; then
            # git config --local user.name "$username"
            if ! git config --local user.name "$name"; then
                echo "Error setting user name."
                # return 1  # Return failure
            else
                echo "User name set successfully."
            fi
        fi

        # Check if user.email is set
        userEmail=$(git config --local user.email)
        if [ -z "$userEmail" ]; then
            if ! git config --local user.email "$email"; then
                echo "Error setting user email."
                # return 1  # Return failure
            else
                echo "User email set successfully."
            fi
        fi

        if ! git remote add origin git@$username:$username/$repoName.git; then
            echo "Error adding remote origin."
            return 1  # Return failure
        else
            echo "Remote origin added successfully."
        fi
        

    else
    
        # git init
        # git add .
        initAddCommit
        read -p "commit message? " commitMessage
        # git commit -m "$commitMessage"
        initAddCommit "$commitMessage"
        if ! git remote add origin git@$username:$username/$repoName.git; then
            echo "Error adding remote origin."
            return 1  # Return failure
        else
            echo "Remote origin added successfully."
        fi
        
        if ! git push -u origin main; then
            echo "Error pushing to GitHub."
            return 1  # Return failure
        fi
        # git remote add origin git@$username:$username/$repoName.git
        # git push -u origin main
    fi
}
export -f sendToGitHub