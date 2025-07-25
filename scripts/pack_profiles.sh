#!/bin/bash

# Check if required arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 VERSION NUMBER VENDOR1 [VENDOR2 ...]"
    echo "Example: $0 2.3.0 1 OrcaFilamentLibrary BBL"
    exit 1
fi

# Get version and number from arguments
VERSION="$1"
NUMBER="$2"
shift 2  # Remove first two arguments, leaving only vendor names

# Set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$SCRIPT_DIR/../profiles/${VERSION}"
ORIGINAL_DIR="$(pwd)"
OUTPUT_FILE="gingerslicer-profiles_ota_${VERSION}.${NUMBER}.zip"
TEMP_DIR="/tmp/orca_profiles_${VERSION}_$$"

# Check if resources directory exists
if [ ! -d "$RESOURCES_DIR" ]; then
    echo "Error: Profiles directory not found at $RESOURCES_DIR"
    exit 1
fi

# If no vendors specified, collect all vendor directories
if [ "$#" -eq 0 ]; then
    VENDORS=()
    for dir in "$RESOURCES_DIR"/*; do
        vendor=$(basename "$dir")
        if [ -d "$RESOURCES_DIR/$vendor" ]; then
            VENDORS+=("$vendor")
        fi
    done
else
    VENDORS=("$@")
fi

# Create temporary directory with profiles root folder
mkdir -p "$TEMP_DIR/profiles"

# Process each vendor
for VENDOR in "${VENDORS[@]}"; do
    echo "Processing vendor: $VENDOR"
    
    # Copy JSON file if it exists
    if [ -f "$RESOURCES_DIR/$VENDOR.json" ]; then
        cp "$RESOURCES_DIR/$VENDOR.json" "$TEMP_DIR/profiles/"
        echo "Added $VENDOR.json"
    else
        echo "Warning: $VENDOR.json not found"
    fi
    
    # Copy vendor directory if it exists
    if [ -d "$RESOURCES_DIR/$VENDOR" ]; then
        cp -r "$RESOURCES_DIR/$VENDOR" "$TEMP_DIR/profiles/"
        echo "Added $VENDOR directory"
    else
        echo "Warning: $VENDOR directory not found"
    fi
done

# Create zip file
cd "$TEMP_DIR"
zip -r "$OUTPUT_FILE" profiles/

# Move zip file to original directory
mv "$OUTPUT_FILE" "$ORIGINAL_DIR/"

# Return to original directory
cd "$ORIGINAL_DIR"

# Clean up
rm -rf "$TEMP_DIR"

# Print results
if [ -f "$OUTPUT_FILE" ]; then
    echo "Created profiles package: $OUTPUT_FILE"
    echo "Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
else
    echo "Error: Failed to create zip file"
    exit 1
fi 