#!/bin/bash

# List of binary file extensions to exclude (case-insensitive)
BINARY_EXTENSIONS=(
    "png" "jpg" "jpeg" "gif" "bmp" "webp" "tiff" "ico"
    "mp3" "wav" "flac" "ogg"
    "mp4" "avi" "mkv" "mov"
    "pdf" "zip" "tar" "gz" "7z" "rar"
    "exe" "dll" "so" "bin"
)

# Convert string to lowercase
to_lowercase() {
    printf '%s' "${1,,}"
}

# Check if a file is binary based on extension or MIME type
is_binary() {
    local file="$1"
    [[ ! -e "$file" ]] && return 0

    local ext
    ext=$(to_lowercase "${file##*.}")
    for binary_ext in "${BINARY_EXTENSIONS[@]}"; do
        [[ "$ext" == "$binary_ext" ]] && return 0
    done

    if command -v file >/dev/null 2>&1; then
        file --mime "$file" 2>/dev/null | grep -q 'charset=binary' && return 0
    fi

    return 1
}

# Map file extension to Markdown language identifier
get_markdown_language() {
    local ext
    ext=$(to_lowercase "$1")
    case "$ext" in
        lua) echo "lua" ;;
        js) echo "javascript" ;;
        jsx) echo "jsx" ;;
        ts) echo "typescript" ;;
        tsx) echo "tsx" ;;
        py) echo "python" ;;
        json) echo "json" ;;
        sh|bash) echo "bash" ;;
        html) echo "html" ;;
        css) echo "css" ;;
        md|markdown) echo "markdown" ;;
        yml|yaml) echo "yaml" ;;
        toml) echo "toml" ;;
        c) echo "c" ;;
        cpp|cxx|cc|hpp|hxx) echo "cpp" ;;
        java) echo "java" ;;
        go) echo "go" ;;
        rs) echo "rust" ;;
        php) echo "php" ;;
        rb) echo "ruby" ;;
        kt|kts) echo "kotlin" ;;
        *) echo "" ;;
    esac
}

# Print file content wrapped in Markdown code fence
print_file_content() {
    local display_name="$1"
    local file="$2"
    is_binary "$file" && return

    local ext="${file##*.}"
    local lang
    lang=$(get_markdown_language "$ext")

    printf '%s\n```%s\n' "$display_name" "$lang"
    cat "$file"
    printf '\n```\n'
}

# Print directory tree, excluding hidden directories and binary files
print_directory_tree() {
    local dir="$1"
    local prefix="$2"
    local entries=()

    while IFS= read -r -d '' name; do
        [[ "$name" == .* ]] && continue
        entries+=("$name")
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -not -path '*/.*' -printf '%f\0' | sort -z)

    local last_index=$(( ${#entries[@]} - 1 ))
    for i in "${!entries[@]}"; do
        local name="${entries[$i]}"
        local path="$dir/$name"
        local connector="├── "
        local next_prefix="$prefix│   "

        if [[ "$i" -eq "$last_index" ]]; then
            connector="└── "
            next_prefix="$prefix    "
        fi

        if [[ -d "$path" ]]; then
            printf '%s%s%s/\n' "$prefix" "$connector" "$name"
            print_directory_tree "$path" "$next_prefix"
        elif ! is_binary "$path"; then
            printf '%s%s%s\n' "$prefix" "$connector" "$name"
        fi
    done
}

# Process a single file
process_file() {
    local file="$1"
    is_binary "$file" && return
    print_file_content "$(basename "$file")" "$file"
}

# Process a directory and its contents
process_directory() {
    local dir="$1"
    local dir_name
    dir_name=$(basename "$dir")

    printf '%s/\n' "$dir_name"
    print_directory_tree "$dir" ""
    printf '\n'

    local first_file=true
    while IFS= read -r -d '' file; do
        [[ ! -f "$file" ]] || is_binary "$file" && continue
        [[ "$first_file" == false ]] && printf '\n'
        local rel_path="${file#$dir/}"
        print_file_content "$dir_name/$rel_path" "$file"
        first_file=false
    done < <(find "$dir" -not -path '*/.*' -type f -print0 | sort -z)
}

# Resolve path (absolute or relative to current directory)
resolve_path() {
    local arg="$1"
    local start_dir="$2"

    if [[ -e "$arg" ]]; then
        echo "$arg"
    elif [[ -e "$start_dir/$arg" ]]; then
        echo "$start_dir/$arg"
    else
        echo ""
    fi
}

# Main function to handle script execution
main() {
    local start_dir
    start_dir=$(pwd)
    local root_name
    root_name=$(basename "$start_dir")

    if [[ $# -eq 0 ]]; then
        process_directory "$start_dir"
        return
    fi

    local proc_items=()
    for arg in "$@"; do
        local path
        path=$(resolve_path "$arg" "$start_dir")
        [[ -z "$path" ]] && continue

        if [[ -d "$path" ]]; then
            proc_items+=("D:$path")
        elif [[ -f "$path" ]] && ! is_binary "$path"; then
            proc_items+=("F:$path")
        fi
    done

    if [[ ${#proc_items[@]} -eq 1 ]]; then
        local entry="${proc_items[0]}"
        local kind="${entry%%:*}"
        local path="${entry#*:}"
        [[ "$kind" == "D" ]] && process_directory "$path" || process_file "$path"
        return
    fi

    # Fix $i to count folders value correctly
    local itemNr=0
    for i in "${!proc_items[@]}"; do
        local entry="${proc_items[$i]}"
        local kind="${entry%%:*}"
        local path="${entry#*:}"

        [[ "$kind" == "D" ]] && process_directory "$path" || process_file "$path"

        if [[ "$itemNr" -lt $(( ${#proc_items[@]} - 1 )) ]]; then
            printf '\n--------------------------------------------------\n\n'
        fi

        ((itemNr++))
    done
}

# Execute main function
main "$@"
