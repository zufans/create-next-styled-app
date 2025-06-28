#!/bin/bash
clear="\x1Bc"
echo "$clear"



process_directory() {
  local target_dir="$1"
  
  # Check if the provided argument is indeed a directory.
  if [[ ! -d "$target_dir" ]]; then
    echo "Error: '$target_dir' is not a valid directory."
    return 1
  fi
  
  # Loop through each file in the directory.
  for file in "$target_dir"/*; do
    # Ensure that it is a regular file.
    if [[ -f "$file" ]]; then
      # Extract the filename (e.g., "NewResumeButton.tsx").
      filename=$(basename "$file")
      # Remove the extension to get the base name (e.g., "NewResumeButton").
      base="${filename%.*}"
      
      # Create a new directory with the base name inside the target directory.
      new_dir="$target_dir/$base"
      mkdir -p "$new_dir"
      
      # Create the first file: base name with .tsx extension.
      file1="$new_dir/${base}.tsx"
      touch "$file1"
      
      # Create the second file: base name appended with .styles and .tsx extension.
      file2="$new_dir/${base}.styles.tsx"
      touch "$file2"
      
      echo "Created folder '$new_dir' with files:"
      echo "  - $(basename "$file1")"
      echo "  - $(basename "$file2")"
    fi
  done
}

dir="src/components/Chat"
process_directory "$dir"

# ls "$dir"