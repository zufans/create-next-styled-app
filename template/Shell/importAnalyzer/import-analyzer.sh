#!/bin/bash
# import-analyzer.sh
# A script to analyze JavaScript/JSX imports and track all dependencies

# Create necessary temp files
tmp_output=$(mktemp)
tmp_files_json=$(mktemp)

# Function to analyze imports in a JavaScript/JSX file
analyze_imports() {
    local input_file="$1"
    local temp_json_file="$2"
    
    # Check if file exists
    if [ ! -f "$input_file" ]; then
        echo "Error: File '$input_file' not found"
        return 1
    fi
    
    echo "Analyzing imports for: $input_file"
    
    # Create a temporary Node.js script to analyze the imports
    local tmp_script=$(mktemp)
    
    # Write Node.js script to the temp file
    cat > "$tmp_script" << 'EOT'
const fs = require('fs');
const path = require('path');

// Get input file and output file from command line args
const inputFile = path.resolve(process.argv[2]);
const outputJsonFile = process.argv[3];
const projectRoot = process.cwd();

// Find src folder for relative path calculations
const srcPath = path.join(projectRoot, 'src');
const hasSrcFolder = fs.existsSync(srcPath);

// Track processed files to avoid circular dependencies
const processedFiles = new Set();
// Store results
const result = {
    directories: new Set(),
    files: new Set()
};

// Function to resolve import paths
function resolveImportPath(importPath, currentFile) {
    const currentDir = path.dirname(currentFile);
    
    // Skip node_modules imports and any path containing node_modules
    if ((!importPath.startsWith('.') && !importPath.startsWith('/') && !importPath.startsWith('@/')) || 
        importPath.includes('node_modules') || currentFile.includes('node_modules')) {
        return { path: importPath, isNodeModule: true };
    }

    // Handle Next.js @ alias (common in React/Next.js projects)
    if (importPath.startsWith('@/')) {
        importPath = importPath.replace('@/', '');
        return resolveWithExtensions(path.join(srcPath, importPath));
    }
    
    // Handle relative imports
    if (importPath.startsWith('.')) {
        return resolveWithExtensions(path.resolve(currentDir, importPath));
    }
    
    // Handle absolute imports from project root
    if (importPath.startsWith('/')) {
        return resolveWithExtensions(path.join(projectRoot, importPath.slice(1)));
    }
    
    return { path: importPath, isNodeModule: true };
}

// Helper function to resolve file with extensions
function resolveWithExtensions(filePath) {
    // If it already has a JS/JSX extension
    if (/\.(js|jsx|ts|tsx)$/.test(filePath)) {
        if (fs.existsSync(filePath)) {
            return { path: filePath, isNodeModule: false };
        }
    }
    
    // Try adding extensions
    const extensions = ['.js', '.jsx', '.ts', '.tsx'];
    for (const ext of extensions) {
        const withExt = filePath + ext;
        if (fs.existsSync(withExt)) {
            return { path: withExt, isNodeModule: false };
        }
    }
    
    // Check for directory with index file
    for (const ext of extensions) {
        const indexFile = path.join(filePath, 'index' + ext);
        if (fs.existsSync(indexFile)) {
            return { path: indexFile, isNodeModule: false };
        }
    }
    
    // If still not resolved, it might be a non-existent file or alias
    return { path: filePath, isNodeModule: false, notFound: true };
}

// Extract imports from JavaScript/JSX content
function extractImports(filePath) {
    try {
        const content = fs.readFileSync(filePath, 'utf-8');
        const imports = [];
        
        // Match ES6 import statements (more comprehensive regex)
        const importRegex = /import(?:["'\s]*([\w*${}\n\r\t, ]+)from\s*)?["'\s]["'\s](.*[@\w_-]+)["'\s].*$/gm;
        let match;
        
        while ((match = importRegex.exec(content)) !== null) {
            if (match[2]) { // The path is always in the second capturing group
                imports.push(match[2].trim());
            }
        }
        
        // Match dynamic imports: import('./module')
        const dynamicImportRegex = /import\(\s*['"]([^'"]+)['"]/g;
        while ((match = dynamicImportRegex.exec(content)) !== null) {
            imports.push(match[1].trim());
        }
        
        // Match require statements
        const requireRegex = /require\(\s*['"]([^'"]+)['"]/g;
        while ((match = requireRegex.exec(content)) !== null) {
            imports.push(match[1].trim());
        }
        
        return imports;
    } catch (error) {
        console.error(`Error reading file ${filePath}:`, error.message);
        return [];
    }
}

// Process a file and track its dependencies
function processFile(filePath) {
    if (processedFiles.has(filePath)) {
        return;
    }
    
    processedFiles.add(filePath);
    result.files.add(filePath);
    result.directories.add(path.dirname(filePath));
    
    const imports = extractImports(filePath);
    
    for (const importPath of imports) {
        const resolved = resolveImportPath(importPath, filePath);
        
        // Skip node modules or not found imports
        if (resolved.isNodeModule || resolved.notFound) {
            continue;
        }
        
        // Process each resolved import recursively
        processFile(resolved.path);
    }
}

// Function to convert absolute paths to src-relative paths
function getSrcRelativePath(absPath) {
    if (hasSrcFolder && absPath.includes('/src/')) {
        const srcIndex = absPath.indexOf('/src/');
        return absPath.slice(srcIndex + 1); // +1 to remove the leading slash
    }
    return absPath;
}

// Begin analysis
processFile(inputFile);

// Filter out node_modules from results
const filteredDirectories = Array.from(result.directories).filter(dir => !dir.includes('node_modules'));
const filteredFiles = Array.from(result.files).filter(file => !file.includes('node_modules'));

// Convert to src-relative paths if src folder exists
const relativeDirs = hasSrcFolder 
    ? filteredDirectories.map(getSrcRelativePath) 
    : filteredDirectories;
    
const relativeFiles = hasSrcFolder 
    ? filteredFiles.map(getSrcRelativePath) 
    : filteredFiles;

// Output results in a formatted way
console.log(`\n===== IMPORT ANALYSIS RESULTS =====`);
console.log(`\nInput File:`);
console.log(`${hasSrcFolder ? getSrcRelativePath(inputFile) : inputFile}`);

console.log(`\nDirectories (${relativeDirs.length}):`);
relativeDirs.sort().forEach(dir => {
    console.log(`${dir}`);
});

console.log(`\nFiles (${relativeFiles.length}):`);
relativeFiles.sort().forEach(file => {
    console.log(`${file}`);
});

// Write just the sorted file list to the temp JSON file
fs.writeFileSync(outputJsonFile, JSON.stringify(relativeFiles.sort()));
EOT

    # Run the Node.js script with the input file and output file
    node "$tmp_script" "$input_file" "$temp_json_file"
    
    # Clean up the temporary script file
    rm "$tmp_script"
    
    return 0
}

# Function to write file list to copy/grabFiles.json
write_to_grab_files() {
    local temp_json_file="$1"
    local grab_files_path="copy/grabFiles.json"
    
    # Ask the user if they want to write the files to grabFiles.json
    echo ""
    echo "Would you like to write these files to copy/grabFiles.json? (y/n)"
    read -p "> " response
    
    if [[ "$response" != "y" && "$response" != "Y" ]]; then
        echo "Files not saved to grabFiles.json."
        return 0
    fi
    
    # Create the copy directory if it doesn't exist
    mkdir -p "copy"
    
    # Check if grabFiles.json exists, create it if it doesn't
    if [ ! -f "$grab_files_path" ]; then
        echo "Creating new $grab_files_path file..."
        echo '{
  "copied": false,
  "files": []
}' > "$grab_files_path"
    fi
    
    # Create a temporary Node.js script to update the JSON file
    local update_script=$(mktemp)
    
    # Write Node.js script to the temp file
    cat > "$update_script" << EOT
const fs = require('fs');

// Read the input JSON file with the new files
const inputJsonFile = process.argv[2];
const fileContent = fs.readFileSync(inputJsonFile, 'utf8');
const newFiles = JSON.parse(fileContent);

// Read the existing grabFiles.json
let grabFilesPath = 'copy/grabFiles.json';
let grabFilesData;

try {
    const grabFilesContent = fs.readFileSync(grabFilesPath, 'utf8');
    grabFilesData = JSON.parse(grabFilesContent);
    
    // Handle case where the file exists but isn't valid JSON
    if (!grabFilesData || typeof grabFilesData !== 'object') {
        grabFilesData = { "copied": false, "files": [] };
    }
    
    // Ensure the files property exists and is an array
    if (!Array.isArray(grabFilesData.files)) {
        grabFilesData.files = [];
    }
} catch (error) {
    console.error('Error reading grabFiles.json:', error.message);
    grabFilesData = { "copied": false, "files": [] };
}

// Add new files without duplicates
const uniqueFiles = new Set([...grabFilesData.files, ...newFiles]);
grabFilesData.files = Array.from(uniqueFiles);

// Write the updated data back to the file
fs.writeFileSync(grabFilesPath, JSON.stringify(grabFilesData, null, 2));

console.log(\`Updated \${grabFilesPath} with \${newFiles.length} new file(s)\`);
console.log(\`File now contains \${grabFilesData.files.length} unique file paths\`);
EOT

    # Run the Node.js script with the temp json file path
    node "$update_script" "$temp_json_file"
    
    # Clean up the temporary script file
    rm "$update_script"
    
    return 0
}

# Main script execution
main() {
    local input_file=""
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$0")"
    
    # If an argument was provided, use it
    if [ "$#" -eq 1 ]; then
        input_file="$1"
    # Otherwise, prompt the user for input
    else
        echo "Enter the path to a JavaScript/JSX file to analyze:"
        read -p "> " input_file
        
        # Trim leading/trailing whitespace
        input_file=$(echo "$input_file" | sed 's/^ *//;s/ *$//')
        
        # Exit if no input provided
        if [ -z "$input_file" ]; then
            echo "No file path provided. Exiting."
            exit 1
        fi
    fi
    
    # Run the analysis function - it will output the results directly
    analyze_imports "$input_file" "$tmp_files_json"
    
    # Write to grabFiles.json if requested
    write_to_grab_files "$tmp_files_json"
    
    # Clean up temp files
    rm -f "$tmp_output" "$tmp_files_json"
}

# Execute the main function with all script arguments
main "$@"