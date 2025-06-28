#!/bin/bash
clear="\x1Bc"
echo "$clear"



update_background_color() {
    local file_path="$1"
    local old_color=" background-color: white;"
    local new_color=" background-color: #2D1937;"
    
    if [ -f "$file_path" ]; then
        # Using awk instead of sed for macOS compatibility
        awk -v old="$old_color" -v new="$new_color" '
        {
            if (found == 0 && index($0, old)) {
                sub(old, new)
                found = 1
            }
            print
        }' "$file_path" > temp_file && mv temp_file "$file_path"
        
        echo "Background color updated successfully in $file_path"
    else
        echo "Error: $file_path does not exist."
        exit 1
    fi
}

# Call the function
filePath="docs/prismaDiagram.svg"
update_background_color "$filePath"

# Can you fix this bach function.
# I keep getting this message: sed: 1: "0,/ background-color: w ...": bad flag in substitute command: '}'