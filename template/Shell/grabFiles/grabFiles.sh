#!/bin/bash
# Shell/grabFiles.sh

# Import colors from bashColors.sh if available
source ./Shell/bashColors.sh 2>/dev/null || {
    # Fallback colors if import fails
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
    echo -e "${YELLOW}Warning: Could not import colors from bashColors.sh, using defaults${NC}"
}

# Define some global variables
COPY_DIR="copy"
JSON_FILE="$COPY_DIR/grabFiles.json"
HOME_DIR="$HOME"
OPTION_DIR="$HOME_DIR/Desktop/AI/code"
NEW_DIR=""
DIR_NUM=0

# Function to grab files from the config and copy to numbered directory
grabFiles() {
    # Create the copy directory if it doesn't exist
    if [ ! -d "$COPY_DIR" ]; then
        mkdir -p "$COPY_DIR"
        echo -e "${BLUE}Created directory:${NC} $COPY_DIR"
    fi

    # Check if the JSON file exists
    if [ ! -f "$JSON_FILE" ]; then
        echo -e "${RED}Error:${NC} $JSON_FILE not found."
        return 1
    fi

    # Check if jq is installed (needed for JSON parsing)
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Error:${NC} The 'jq' utility is not installed. Please install it to use this script."
        echo -e "    On Ubuntu/Debian: sudo apt-get install jq"
        echo -e "    On macOS: brew install jq"
        return 1
    fi

    # Check if files have already been copied
    COPIED=$(cat "$JSON_FILE" | jq -r '.copied')
    if [ "$COPIED" = "true" ]; then
        echo -e "${YELLOW}Warning:${NC} Files have already been marked as copied in $JSON_FILE."
        read -p "Continue anyway? (y/n): " CONTINUE
        if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Operation cancelled.${NC}"
            return 0
        fi
    fi

    # Find the next directory number
    DIR_NUM=1
    while [ -d "$COPY_DIR/$DIR_NUM" ]; do
        DIR_NUM=$((DIR_NUM + 1))
    done

    # Create the new numbered directory
    NEW_DIR="$COPY_DIR/$DIR_NUM"
    mkdir -p "$NEW_DIR"
    echo -e "${BLUE}Created directory:${NC} $NEW_DIR"

    # Get the list of files from the JSON file
    # This uses jq to parse the JSON and get the files array - updated for flat array format
    FILES_JSON=$(cat "$JSON_FILE" | jq -r '.files[]')

    # Initialize arrays to track copied files and errors
    declare -a COPIED_FILES=()
    declare -a ERROR_FILES=()

    # Copy each file to the destination - without preserving folder structure
    echo -e "${CYAN}Starting file copy process...${NC}"
    for FILE in $FILES_JSON; do
        if [ -f "$FILE" ]; then
            # Get just the base filename
            BASENAME=$(basename "$FILE")
            
            # Copy the file directly to the numbered directory
            cp "$FILE" "$NEW_DIR/$BASENAME"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Copied:${NC} $FILE -> $NEW_DIR/$BASENAME"
                COPIED_FILES+=("$FILE")
            else
                echo -e "${RED}Error copying:${NC} $FILE"
                ERROR_FILES+=("$FILE")
            fi
        else
            echo -e "${RED}File not found:${NC} $FILE"
            ERROR_FILES+=("$FILE")
        fi
    done

    # Create a report directory and file
    REPORT_DIR="$NEW_DIR/report"
    mkdir -p "$REPORT_DIR"
    echo -e "${BLUE}Created report directory:${NC} $REPORT_DIR"

    REPORT_FILE="$REPORT_DIR/report.json"
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    USER=$(whoami)

    # Initialize the report JSON structure
    echo "{" > "$REPORT_FILE"
    echo "  \"report_info\": {" >> "$REPORT_FILE"
    echo "    \"timestamp\": \"$TIMESTAMP\"," >> "$REPORT_FILE"
    echo "    \"user\": \"$USER\"," >> "$REPORT_FILE"
    echo "    \"directory\": \"$NEW_DIR\"" >> "$REPORT_FILE"
    echo "  }," >> "$REPORT_FILE"

    # Add copied files to the report
    echo "  \"files_copied\": [" >> "$REPORT_FILE"
    for ((i=0; i<${#COPIED_FILES[@]}; i++)); do
        COMMA=""
        if [ $i -lt $((${#COPIED_FILES[@]}-1)) ]; then
            COMMA=","
        fi
        echo "    \"${COPIED_FILES[$i]}\"$COMMA" >> "$REPORT_FILE"
    done
    echo "  ]," >> "$REPORT_FILE"

    # Add errors to the report
    echo "  \"errors\": [" >> "$REPORT_FILE"
    for ((i=0; i<${#ERROR_FILES[@]}; i++)); do
        COMMA=""
        if [ $i -lt $((${#ERROR_FILES[@]}-1)) ]; then
            COMMA=","
        fi
        echo "    \"${ERROR_FILES[$i]}\"$COMMA" >> "$REPORT_FILE"
    done
    echo "  ]," >> "$REPORT_FILE"

    # Add summary stats
    echo "  \"summary\": {" >> "$REPORT_FILE"
    echo "    \"total_copied\": ${#COPIED_FILES[@]}," >> "$REPORT_FILE"
    echo "    \"total_errors\": ${#ERROR_FILES[@]}" >> "$REPORT_FILE"
    echo "  }" >> "$REPORT_FILE"
    echo "}" >> "$REPORT_FILE"

    echo -e "${BLUE}Created report:${NC} $REPORT_FILE"

    # Update the grabFiles.json file to set copied to true
    TMP_FILE=$(mktemp)
    cat "$JSON_FILE" | jq '.copied = true' > "$TMP_FILE" && mv "$TMP_FILE" "$JSON_FILE"

    echo -e "${GREEN}Updated:${NC} $JSON_FILE (copied = true)"
    echo -e "${BOLD}Finished grabbing files.${NC} Copied ${#COPIED_FILES[@]} files, encountered ${#ERROR_FILES[@]} errors."
    
    return 0
}

# Function to save files to the option directory
saveToOptionDir() {
    # Check if the latest directory exists
    if [ ! -d "$NEW_DIR" ]; then
        echo -e "${RED}Error:${NC} No files have been grabbed yet. Run the grabFiles function first."
        return 1
    fi
    
    # Ask user if they want to save files to the option directory
    echo -e "${CYAN}Would you like to also save the files to ${BOLD}$OPTION_DIR${NC}?"
    read -p "Save files? (y/n): " SAVE_OPTION
    
    if [[ $SAVE_OPTION =~ ^[Yy]$ ]]; then
        # Create the option directory if it doesn't exist
        if [ ! -d "$OPTION_DIR" ]; then
            mkdir -p "$OPTION_DIR"
            echo -e "${BLUE}Created directory:${NC} $OPTION_DIR"
        fi
        
        # Create a numbered directory in the option directory
        DEST_DIR="$OPTION_DIR/$DIR_NUM"
        mkdir -p "$DEST_DIR"
        
        # Copy files from the new directory to the option directory
        cp -r "$NEW_DIR"/* "$DEST_DIR"
        
        # Remove the report folder from the destination
        rm -rf "$DEST_DIR/report"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Successfully copied files to:${NC} $DEST_DIR"
            
            # Ask if user wants to change file extensions
            echo -e "${CYAN}Would you like to change the file extensions?${NC}"
            read -p "Change extensions? (y/n): " CHANGE_EXT
            
            if [[ $CHANGE_EXT =~ ^[Yy]$ ]]; then
                # Ask for the new extension
                echo -e "${CYAN}What extension would you like to use?${NC}"
                read -p "Extension (without dot, e.g. 'txt' or 'js'): " NEW_EXT
                
                # Validate extension input
                if [[ -z "$NEW_EXT" ]]; then
                    echo -e "${YELLOW}No extension provided. Files will keep their original extensions.${NC}"
                else
                    # Ensure NEW_EXT doesn't start with a dot
                    NEW_EXT=${NEW_EXT#.}
                    
                    # Initialize counter for renamed files
                    local renamed_count=0
                    
                    # Rename all files in the destination directory
                    for file in "$DEST_DIR"/*; do
                        if [ -f "$file" ]; then
                            # Get the filename without extension
                            local filename=$(basename "$file")
                            local base="${filename%.*}"
                            
                            # Rename the file with the new extension
                            mv "$file" "$DEST_DIR/$base.$NEW_EXT"
                            
                            if [ $? -eq 0 ]; then
                                renamed_count=$((renamed_count + 1))
                                echo -e "${GREEN}Renamed:${NC} $filename -> $base.$NEW_EXT"
                            else
                                echo -e "${RED}Error renaming:${NC} $filename"
                            fi
                        fi
                    done
                    
                    echo -e "${GREEN}Successfully renamed $renamed_count files with .$NEW_EXT extension${NC}"
                fi
            else
                echo -e "${YELLOW}File extensions not changed.${NC}"
            fi
        else
            echo -e "${RED}Error:${NC} Failed to copy files to $DEST_DIR"
            return 1
        fi
    else
        echo -e "${YELLOW}Files not saved to option directory.${NC}"
    fi
    
    return 0
}

# Main execution
# Run the grabFiles function
grabFiles

# If grabFiles was successful, offer to save files to option directory
if [ $? -eq 0 ]; then
    saveToOptionDir
fi