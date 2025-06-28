#!/bin/bash
# Shell/Distribute/reverseDistribute.sh

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

# Global array to track restored files
declare -a RESTORED_FILES=()
declare -a REMOVED_FILES=()
declare -a RECREATED_FILES=()

# Function to reverse the most recent distribution
reverseDistribute() {
    local backup_dir="Backup"
    local distribute_dir="distribute"
    
    # Check if backup directory exists
    if [ ! -d "$backup_dir" ]; then
        printf "${RED}Error:${NC} '$backup_dir' directory not found.\n"
        exit 1
    fi
    
    # Create distribute directory if it doesn't exist
    if [ ! -d "$distribute_dir" ]; then
        mkdir -p "$distribute_dir"
        printf "${BLUE}Created directory:${NC} %s\n" "$distribute_dir"
    fi
    
    # Find the most recent backup (highest number)
    local latest_backup=$(find "$backup_dir" -maxdepth 1 -type d | grep -E '/[0-9]+$' | sort -n | tail -1)
    
    if [ -z "$latest_backup" ]; then
        printf "${RED}Error:${NC} No backup directories found in '$backup_dir'.\n"
        exit 1
    fi
    
    printf "${BLUE}Found latest backup:${NC} %s\n" "$latest_backup"
    
    # Check for distribution.json
    local distribution_json="$latest_backup/distribution.json"
    if [ ! -f "$distribution_json" ]; then
        printf "${RED}Error:${NC} Distribution log file not found: '$distribution_json'.\n"
        exit 1
    fi
    
    # Extract timestamp and user info
    local timestamp=$(jq -r '.distribution_info.timestamp' "$distribution_json")
    local user=$(jq -r '.distribution_info.user' "$distribution_json")
    local processed_count=$(jq -r '.distribution_info.processed_count' "$distribution_json")
    
    printf "${BOLD}Reversing distribution${NC} from ${YELLOW}%s${NC} by ${YELLOW}%s${NC}\n" "$timestamp" "$user"
    printf "Original distribution processed ${YELLOW}%s${NC} files\n\n" "$processed_count"
    
    # Create a new log file for the reversal
    local reversal_time=$(date "+%Y-%m-%d %H:%M:%S")
    local reversal_log="$latest_backup/reversal.json"
    
    # Initialize reversal log JSON
    cat > "$reversal_log" << EOF
{
  "reversal_info": {
    "timestamp": "$reversal_time",
    "user": "$(whoami)",
    "original_distribution": "$timestamp",
    "backup_directory": "$latest_backup"
  },
  "actions": []
}
EOF
    
    # Count the files to be processed
    local file_count=$(jq '.files | length' "$distribution_json")
    printf "${CYAN}Processing ${BOLD}%s${NC} ${CYAN}files...${NC}\n" "$file_count"
    
    # Process the files in reverse order for proper restore sequence
    for ((i=file_count-1; i>=0; i--)); do
        local source=$(jq -r ".files[$i].source" "$distribution_json")
        local destination=$(jq -r ".files[$i].destination" "$distribution_json")
        local status=$(jq -r ".files[$i].status" "$distribution_json")
        local original_filename=$(basename "$source")
        
        printf "${CYAN}Processing [%d/${file_count}]:${NC} %s -> %s (Status: %s)\n" "$((i+1))" "$original_filename" "$destination" "$status"
        
        case "$status" in
            "moved")
                # Recreate the original file in distribute/ before removing the destination
                if [ -f "$destination" ]; then
                    # Copy the file back to the distribute folder
                    cp "$destination" "$distribute_dir/$original_filename"
                    printf "${GREEN}Recreated${NC} %s in distribute folder\n" "$original_filename"
                    RECREATED_FILES+=("$distribute_dir/$original_filename")
                    
                    # Now remove the destination file
                    rm "$destination"
                    printf "${GREEN}Removed${NC} %s\n" "$destination"
                    REMOVED_FILES+=("$destination")
                    
                    # Update reversal log
                    tmp_file=$(mktemp)
                    jq --arg dest "$destination" --arg src "$distribute_dir/$original_filename" --arg time "$(date '+%Y-%m-%d %H:%M:%S')" \
                    '.actions += [{"destination": $dest, "source": $src, "action": "recreated_and_removed", "timestamp": $time}]' "$reversal_log" > "$tmp_file"
                    mv "$tmp_file" "$reversal_log"
                else
                    printf "${YELLOW}Warning:${NC} File %s not found, already removed?\n" "$destination"
                    
                    # Update reversal log for missing file
                    tmp_file=$(mktemp)
                    jq --arg dest "$destination" --arg time "$(date '+%Y-%m-%d %H:%M:%S')" \
                    '.actions += [{"destination": $dest, "action": "not_found", "timestamp": $time}]' "$reversal_log" > "$tmp_file"
                    mv "$tmp_file" "$reversal_log"
                fi
                ;;
                
            "backed_up")
                # Restore original file and recreate the file in distribute/
                local backup_file=$(jq -r ".files[$i].backup_file" "$distribution_json")
                
                if [ -f "$backup_file" ]; then
                    # Ensure the destination directory exists
                    local dest_dir=$(dirname "$destination")
                    mkdir -p "$dest_dir" 2>/dev/null
                    
                    # Restore the backup file to its original location
                    cp "$backup_file" "$destination"
                    printf "${GREEN}Restored${NC} %s -> %s\n" "$backup_file" "$destination"
                    RESTORED_FILES+=("$destination")
                    
                    # Also recreate the file in distribute/ folder
                    if [ -f "$destination" ]; then
                        cp "$destination" "$distribute_dir/$original_filename"
                        printf "${GREEN}Recreated${NC} %s in distribute folder\n" "$original_filename"
                        RECREATED_FILES+=("$distribute_dir/$original_filename")
                    fi
                    
                    # Update reversal log
                    tmp_file=$(mktemp)
                    jq --arg dest "$destination" --arg backup "$backup_file" --arg src "$distribute_dir/$original_filename" --arg time "$(date '+%Y-%m-%d %H:%M:%S')" \
                    '.actions += [{"destination": $dest, "source": $src, "action": "restored_and_recreated", "backup_file": $backup, "timestamp": $time}]' "$reversal_log" > "$tmp_file"
                    mv "$tmp_file" "$reversal_log"
                else
                    printf "${RED}Error:${NC} Backup file %s not found!\n" "$backup_file"
                    
                    # Try to recreate from destination if possible
                    if [ -f "$destination" ]; then
                        cp "$destination" "$distribute_dir/$original_filename"
                        printf "${YELLOW}Warning:${NC} Backup file missing, but recreated %s in distribute folder from destination\n" "$original_filename"
                        RECREATED_FILES+=("$distribute_dir/$original_filename")
                    fi
                    
                    # Update reversal log for missing backup file
                    tmp_file=$(mktemp)
                    jq --arg dest "$destination" --arg backup "$backup_file" --arg time "$(date '+%Y-%m-%d %H:%M:%S')" \
                    '.actions += [{"destination": $dest, "action": "backup_missing", "backup_file": $backup, "timestamp": $time}]' "$reversal_log" > "$tmp_file"
                    mv "$tmp_file" "$reversal_log"
                fi
                ;;
                
            "skipped")
                # For skipped files, we don't need to do anything as they should still be in distribute/
                printf "${BLUE}Skipped${NC} %s (was skipped in original distribution)\n" "$destination"
                
                # Check if the file still exists in distribute/
                if [ ! -f "$distribute_dir/$original_filename" ]; then
                    printf "${YELLOW}Warning:${NC} Original file %s no longer exists in distribute folder\n" "$original_filename"
                fi
                
                # Update reversal log
                tmp_file=$(mktemp)
                jq --arg dest "$destination" --arg time "$(date '+%Y-%m-%d %H:%M:%S')" \
                '.actions += [{"destination": $dest, "action": "skipped", "timestamp": $time}]' "$reversal_log" > "$tmp_file"
                mv "$tmp_file" "$reversal_log"
                ;;
                
            *)
                printf "${RED}Unknown status:${NC} %s for %s\n" "$status" "$destination"
                ;;
        esac
    done
    
    # Update the summary in the reversal log
    local removed_count=${#REMOVED_FILES[@]}
    local restored_count=${#RESTORED_FILES[@]}
    local recreated_count=${#RECREATED_FILES[@]}
    
    tmp_file=$(mktemp)
    jq --arg removed "$removed_count" --arg restored "$restored_count" --arg recreated "$recreated_count" \
    '.reversal_info += {"removed_count": $removed, "restored_count": $restored, "recreated_count": $recreated}' "$reversal_log" > "$tmp_file"
    mv "$tmp_file" "$reversal_log"
    
    # Print summary
    printf "\n${GREEN}Reversal complete.${NC}\n"
    printf "Removed ${BOLD}%d${NC} files, restored ${BOLD}%d${NC} files, recreated ${BOLD}%d${NC} files in distribute folder.\n" "$removed_count" "$restored_count" "$recreated_count"
    printf "Reversal log: ${CYAN}%s${NC}\n\n" "$reversal_log"
    
    # List recreated files
    if [ ${#RECREATED_FILES[@]} -gt 0 ]; then
        printf "${BLUE}Files recreated in distribute folder:${NC}\n"
        for file in "${RECREATED_FILES[@]}"; do
            printf "  %s\n" "$file"
        done
        printf "\n"
    fi
    
    # Open restored files in editor if any
    if [ ${#RESTORED_FILES[@]} -gt 0 ]; then
        printf "${BLUE}Restored destination files:${NC}\n"
        for file in "${RESTORED_FILES[@]}"; do
            printf "  %s\n" "$file"
            code "$file" &>/dev/null &
        done
    fi
}

# Run the reversal
reverseDistribute
