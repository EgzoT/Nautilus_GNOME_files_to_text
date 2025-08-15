#!/bin/bash

# Path to generator script
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
GENERATOR="$SCRIPT_DIR/files_to_text.sh"

# Ensure generator script exists and is executable
if [[ ! -x "$GENERATOR" ]]; then
    zenity --error --title="Error" --text="Generator script \"$GENERATOR\" does not exist or is not executable."
    exit 1
fi

# Determine output directory (same as where the script is run from in Nautilus)
if [[ $# -eq 0 ]]; then
    zenity --error --title="Error" --text="No files or folders selected."
    exit 1
fi

# Determine output file name based on selection
if [[ $# -eq 1 && -d "$1" ]]; then
    output_file="$(dirname "$1")/$(basename "$1").md"
else
    output_file="$(dirname "$1")/files_text.md"
fi

# Check if file already exists
if [[ -e "$output_file" ]]; then
    zenity --error --title="Error" --text="File \"$output_file\" already exists."
    exit 1
fi

# Run generator and save output
if ! "$GENERATOR" "$@" > "$output_file"; then
    zenity --error --title="Error" --text="Failed to generate file."
    exit 1
fi

# Success message
zenity --info --title="Success" --text="Output saved to: $output_file"
