#!/bin/bash
# clear="\x1Bc"


# The -e flag is checking whether something (a file, directory, symbolic link, etc.) exists at the path stored in "$token_file_path".
# A file system object is objects include files, directories, symbolic links, and special files like pipes, sockets, and device files.
# Symbolic Link (Symlink): AKA symlink or soft link is a file that serves as a reference or pointer to another file or directory.

# Function to authenticate with GitHub
function githubAuth(){
    local token_file_path=$1
    # token_file_path=~/"$token_file_path"
    if [ -e $token_file_path ]; then
        # token=$(cat $token_file_path)
        local token=$(cat $token_file_path)
        echo $token | gh auth login --with-token 2>&1 >/dev/null
        if [[ $? -eq 0 ]]; then
            echo "Authentication successful"
        else
            echo "Authentication failed"
            exit 0
        fi
    else
        echo "File not found: $token_file_path\n"
        echo "Go watch this tutorial as to making a personal access token at https://www.youtube.com/watch?v=W9zTttHeoHk"
        echo "When creating personal access token make sure you give it read:org permission"
        echo "Once you have created a personal access token in ./.ssh/personal_access_token/<username>__personal_access_token.txt"
        exit 0
    fi
}

export -f githubAuth