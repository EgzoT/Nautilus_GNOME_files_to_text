#!/bin/bash

# Get the absolute path to the folder where this script is located
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
GENERATOR="$SCRIPT_DIR/files_to_text.sh"

# Check if generator script exists and is executable
if [[ ! -x "$GENERATOR" ]]; then
    echo "Error: \"$GENERATOR\" does not exist or is not executable" >&2
    exit 1
fi

# Function to open a terminal safely
open_terminal() {
    local bash_cmd='bash "$0" "$@"; echo; read -p "Press Enter to close..."'

    if command -v x-terminal-emulator >/dev/null 2>&1; then
        x-terminal-emulator -e bash -c "$bash_cmd" "$GENERATOR" "$@"
    elif command -v gnome-terminal >/dev/null 2>&1; then
        gnome-terminal -- bash -c "$bash_cmd" "$GENERATOR" "$@"
    elif command -v konsole >/dev/null 2>&1; then
        konsole --noclose -e bash -c "$bash_cmd" "$GENERATOR" "$@"
    elif command -v xfce4-terminal >/dev/null 2>&1; then
        xfce4-terminal --hold -e bash -c "$bash_cmd" "$GENERATOR" "$@"
    elif command -v mate-terminal >/dev/null 2>&1; then
        mate-terminal -- bash -c "$bash_cmd" "$GENERATOR" "$@"
    elif command -v xterm >/dev/null 2>&1; then
        xterm -hold -e bash -c "$bash_cmd" "$GENERATOR" "$@"
    else
        echo "No terminal emulator found. Running directly:"
        echo
        bash "$GENERATOR" "$@"
        echo
        read -p "Press Enter to close..."
        return 1
    fi
}

# Call the function
open_terminal "$@"
