#!/bin/bash
clear="\x1Bc"
echo "$clear"

# Function to check directory and create if needed
create_dir_and_file() {
    local file_path
    local dir_path
    local filename

    while true; do
        read -p "Enter the file path: " file_path
        
        # Trim leading/trailing whitespace
        file_path=$(echo "$file_path" | sed 's/^ *//;s/ *$//')

        # Check for empty input
        if [[ -z "$file_path" ]]; then
            echo "Error: File path cannot be empty."
            continue
        fi

        # Check for trailing slash
        if [[ "$file_path" == */ ]]; then
            echo "Error: File path cannot end with '/'."
            continue
        fi

        # Extract filename and validate
        filename=$(basename "$file_path")
        if [[ -z "$filename" ]]; then
            echo "Error: Invalid file name."
            continue
        fi

        break
    done

    # dir_path=$(dirname "$file_path")

    # # Create directory if needed
    # if [ -d "$dir_path" ]; then
    #     echo "Directory exists: $dir_path"
    # else
    #     mkdir -p "$dir_path"
    #     echo "Created directory: $dir_path"
    # fi

    # Create file if needed
    if [ -e "$file_path" ]; then
        echo "File already exists: $file_path"
        code "$file_path"
    else
        touch "$file_path"
        echo "Created file: $file_path"
        code "$file_path"
    fi
}

create_dir_and_file
# Example usage
# create_dir_and_file "src/app/dashboard/example/page.js"
# Instade of passing the file path as an input, have create_dir_and_file ask the user for the file path.

# Have the create_dir_and_file function valdate that the user actually entered in a file path.