#!/bin/bash
# Shell/Distribute/distribute.sh

# Import colors from bashColors.sh
source ./Shell/bashColors.sh || {
    # Fallback colors if import fails
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
    printf "${YELLOW}Warning: Could not import colors from bashColors.sh, using defaults${NC}\n"
}

# Global array to store moved files
declare -a MOVED_FILES=()

# Function to distribute files from the 'distribute' folder
distribute() {
    local distribute_dir="distribute"
    local backup_dir="Backup"
    
    # Check if distribute directory exists
    if [ ! -d "$distribute_dir" ]; then
        printf "${RED}Error:${NC} '$distribute_dir' directory not found.\n"
        exit 1
    fi
    
    # Create backup directory if it doesn't exist
    if [ ! -d "$backup_dir" ]; then
        mkdir -p "$backup_dir"
    fi
    
    # Find the next backup number
    local backup_num=1
    while [ -d "$backup_dir/$backup_num" ]; do
        backup_num=$((backup_num + 1))
    done
    
    # Create the numbered backup directory
    mkdir -p "$backup_dir/$backup_num"
    printf "${BLUE}Created backup directory:${NC} %s\n" "$backup_dir/$backup_num"
    
    # Initialize the log file
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local user=$(whoami)
    local log_file="$backup_dir/$backup_num/distribution.json"
    
    # Create the JSON structure
    cat > "$log_file" << EOF
{
  "distribution_info": {
    "timestamp": "$timestamp",
    "user": "$user",
    "backup_directory": "$backup_dir/$backup_num"
  },
  "files": []
}
EOF
    
    # Process each file in the distribute directory
    local processed_count=0
    local backup_count=0
    local file_count=0
    
    # Check if the directory has files
    for file in "$distribute_dir"/*; do
        if [ -f "$file" ]; then
            file_count=$((file_count + 1))
        fi
    done
    
    if [ $file_count -eq 0 ]; then
        printf "${YELLOW}No files found in %s directory.${NC}\n" "$distribute_dir"
        return
    fi
    
    # Process all files
    for file in "$distribute_dir"/*; do
        if [ -f "$file" ]; then
            # Process the file
            process_file "$file" "$backup_dir/$backup_num" "$log_file"
            local status=$?
            
            if [ $status -eq 1 ] || [ $status -eq 2 ]; then
                processed_count=$((processed_count + 1))
                
                if [ $status -eq 2 ]; then
                    backup_count=$((backup_count + 1))
                fi
            fi
        fi
    done
    
    # Update the summary in the log file
    tmp_file=$(mktemp)
    cat "$log_file" | jq --arg processed "$processed_count" --arg backed_up "$backup_count" \
    '.distribution_info += {"processed_count": $processed, "backup_count": $backed_up}' > "$tmp_file"
    mv "$tmp_file" "$log_file"
    
    # Print summary
    if [ $processed_count -eq 0 ]; then
        printf "${YELLOW}No files processed.${NC}\n"
    else
        printf "\n${GREEN}Distribution complete.${NC} Processed ${BOLD}%d${NC} files, backed up ${BOLD}%d${NC} files in ${BLUE}%s${NC}\n" "$processed_count" "$backup_count" "$backup_dir/$backup_num"
        printf "Log file created: ${CYAN}%s${NC}\n\n" "$log_file"
    fi
    
    # Display all moved files and open them in code editor
    for dest_path in "${MOVED_FILES[@]}"; do
        printf "${GREEN}Moved to${NC} %s\n" "$dest_path"
        code "$dest_path" &>/dev/null &
    done
}

# Function to process a single file
process_file() {
    local file_path="$1"
    local backup_dir="$2"
    local log_file="$3"
    local filename=$(basename "$file_path")
    
    # Extract the destination path from the first line of the file
    local first_line=$(head -n 1 "$file_path")
    local dest_path=""
    
    # Handle different comment styles
    if [[ "$first_line" == "//"* ]]; then
        dest_path=$(echo "$first_line" | sed 's/\/\/ *//')
    elif [[ "$first_line" == "#"* ]]; then
        dest_path=$(echo "$first_line" | sed 's/# *//')
    else
        printf "${RED}Error:${NC} First line of %s must start with '// path/to/file.ext' or '# path/to/file.ext'\n" "$filename"
        return 0  # Return 0 for error
    fi
    
    printf "${CYAN}Processing${NC} %s -> ${BOLD}%s${NC}\n" "$filename" "$dest_path"
    
    # Create destination directory if it doesn't exist
    local dest_dir=$(dirname "$dest_path")
    if [ ! -d "$dest_dir" ]; then
        mkdir -p "$dest_dir"
        printf "${BLUE}Created directory:${NC} %s\n" "$dest_dir"
    fi
    
    local was_backed_up=false
    local original_file=""
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local file_content=$(cat "$file_path" | head -n 10 | grep -v "^[//#]" | tr -d '\n' | sed 's/"/\\"/g' | cut -c 1-100)
    if [ -z "$file_content" ]; then
        file_content="[Empty or only comments]"
    else
        file_content="${file_content}..."
    fi
    
    # Check if destination file already exists
    if [ -f "$dest_path" ]; then
        printf "${YELLOW}File '%s' already exists. Overwrite?${NC} (y/n): " "$dest_path"
        read confirm
        if [[ $confirm != [yY] ]]; then
            printf "${YELLOW}Skipping${NC} %s\n" "$filename"
            
            # Update log file for skipped file
            tmp_file=$(mktemp)
            cat "$log_file" | jq --arg src "$file_path" --arg dest "$dest_path" --arg time "$timestamp" \
            '.files += [{"source": $src, "destination": $dest, "timestamp": $time, "status": "skipped", "preview": ""}]' > "$tmp_file"
            mv "$tmp_file" "$log_file"
            
            return 0  # Return 0 for skipped
        fi
        
        # Get the filename portion of the destination path
        local dest_filename=$(basename "$dest_path")
        original_file="$backup_dir/$dest_filename"
        
        # Backup the existing file
        cp "$dest_path" "$original_file"
        printf "${GREEN}Backed up existing file to${NC} %s\n" "$original_file"
        was_backed_up=true
        
        # Move the distribute file to the destination
        mv "$file_path" "$dest_path"
        
        # Add the destination path to the global array
        MOVED_FILES+=("$dest_path")
        
        # Update log file
        tmp_file=$(mktemp)
        cat "$log_file" | jq --arg src "$file_path" --arg dest "$dest_path" --arg time "$timestamp" \
        --arg backup "$original_file" --arg preview "$file_content" \
        '.files += [{"source": $src, "destination": $dest, "timestamp": $time, "status": "backed_up", "backup_file": $backup, "preview": $preview}]' > "$tmp_file"
        mv "$tmp_file" "$log_file"
        
        return 2  # Return 2 for processed with backup
    else
        # Move the file to the destination (no backup needed)
        mv "$file_path" "$dest_path"
        
        # Add the destination path to the global array
        MOVED_FILES+=("$dest_path")
        
        # Update log file
        tmp_file=$(mktemp)
        cat "$log_file" | jq --arg src "$file_path" --arg dest "$dest_path" --arg time "$timestamp" \
        --arg preview "$file_content" \
        '.files += [{"source": $src, "destination": $dest, "timestamp": $time, "status": "moved", "preview": $preview}]' > "$tmp_file"
        mv "$tmp_file" "$log_file"
        
        return 1  # Return 1 for processed without backup
    fi
}

distribute