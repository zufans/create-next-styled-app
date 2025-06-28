#!/bin/bash
clear="\x1Bc"
echo "$clear"

# Function to check directory and create if needed
create_files() {
    # Check if arguments were provided
    if [ $# -eq 0 ]; then
        # If no arguments, prompt for file paths
        local file_paths=()
        local input=""
        
        echo "Enter file paths (one per line, enter empty line to finish):"
        while true; do
            read -p "> " input
            
            # Exit loop if input is empty
            if [[ -z "$input" ]]; then
                break
            fi
            
            # Add to array
            file_paths+=("$input")
        done
        
        # Process each file path
        for file_path in "${file_paths[@]}"; do
            process_file "$file_path"
        done
    else
        # If arguments were provided, process each one
        for file_path in "$@"; do
            process_file "$file_path"
        done
    fi
}

# Function to process a single file path
process_file() {
    local file_path="$1"
    
    # Trim leading/trailing whitespace
    file_path=$(echo "$file_path" | sed 's/^ *//;s/ *$//')
    
    # Check for empty input
    if [[ -z "$file_path" ]]; then
        echo "Error: File path cannot be empty."
        return 1
    fi
    
    # Check for trailing slash
    if [[ "$file_path" == */ ]]; then
        echo "Error: File path cannot end with '/'."
        return 1
    fi
    
    # Extract filename and validate
    local filename=$(basename "$file_path")
    if [[ -z "$filename" ]]; then
        echo "Error: Invalid file name."
        return 1
    fi
    
    # Get directory path
    local dir_path=$(dirname "$file_path")
    
    # Create directory if needed
    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path"
        echo "Created directory: $dir_path"
    fi
    
    # Create file if needed
    if [ -e "$file_path" ]; then
        echo "File already exists: $file_path"
    else
        touch "$file_path"
        echo "Created file: $file_path"
    fi
    
    # Open file in VSCode if it exists
    if command -v code &> /dev/null; then
        code "$file_path"
    else
        echo "VSCode not found in PATH. File created but not opened."
    fi
    
    return 0
}

# Main execution
# Check if script is being sourced or executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Remove the script name from arguments (if running as npm script)
    if [[ "$1" == "$0" ]]; then
        shift
    fi
    
    create_files "$@"
fi

# Make function available for export/sourcing
export -f create_files
export -f process_file


# Usage: npm run touchmultiple -- src/components/Button.jsx src/components/Card.jsx