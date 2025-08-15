#!/bin/bash

# =============================
# List of binary file extensions to exclude (case-insensitive)
# Add/remove extensions as needed
# =============================
BINARY_EXTENSIONS=(
    "*.png" "*.jpg" "*.jpeg" "*.gif" "*.bmp" "*.webp" "*.tiff" "*.ico"
    "*.mp3" "*.wav" "*.flac" "*.ogg"
    "*.mp4" "*.avi" "*.mkv" "*.mov"
    "*.pdf" "*.zip" "*.tar" "*.gz" "*.7z"
    "*.exe" "*.dll" "*.so" "*.bin"
)
# =============================

# Starting directory
start_dir="$(pwd)"
root_name="$(basename "$start_dir")"

# Generate -prune expression for find from BINARY_EXTENSIONS
bin_prune=()
for ext in "${BINARY_EXTENSIONS[@]}"; do
    bin_prune+=(-o -iname "$ext")
done

# Draw directory tree without using `tree`
print_tree() {
    local dir="$1"
    local prefix="$2"

    local entries=()
    while IFS= read -r -d '' name; do
        [[ "$name" == .* ]] && continue
        entries+=("$name")
    done < <(find "$dir" -mindepth 1 -maxdepth 1 \
                \( -path '*/.*' "${bin_prune[@]}" -prune \) -o \
                -printf '%f\0' | sort -z)

    local last_index=$(( ${#entries[@]} - 1 ))
    for i in "${!entries[@]}"; do
        local name="${entries[$i]}"
        local path="$dir/$name"

        local connector="├── "
        local next_prefix="${prefix}│   "
        if [ "$i" -eq "$last_index" ]; then
            connector="└── "
            next_prefix="${prefix}    "
        fi

        if [ -d "$path" ]; then
            echo "${prefix}${connector}${name}/"
            print_tree "$path" "$next_prefix"
        else
            echo "${prefix}${connector}${name}"
        fi
    done
}

# Map file extensions to Markdown language syntax highlighting
get_lang() {
    case "${1,,}" in
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

# Output file content with language detection, skip binary files
print_file_content() {
    local file="$1"
    # Skip binary files based on MIME type
    if file --mime "$file" | grep -q 'charset=binary'; then
        return
    fi

    local ext="${file##*.}"
    local lang
    lang="$(get_lang "$ext")"

    if [ -n "$lang" ]; then
        printf '```%s\n' "$lang"
    else
        echo '```'
    fi
    cat "$file"
    echo
    echo '```'
}

# Process a directory: print tree + files content
process_dir() {
    local dir="$1"
    local dir_name
    dir_name="$(basename "$dir")"

    echo "${dir_name}/"
    print_tree "$dir" ""
    echo

    find "$dir" \
        \( -path '*/.*' "${bin_prune[@]}" -prune \) -o \
        -type f -print0 | sort -z |
    while IFS= read -r -d '' file; do
        rel_path="${file#$dir/}"
        echo "${dir_name}/${rel_path}"
        print_file_content "$file"
        echo
    done
}

# Process a single file
process_file() {
    local file="$1"
    local filename
    filename="$(basename "$file")"

    echo "$filename"
    print_file_content "$file"
    echo
}

# Main logic based on passed arguments
if [ $# -eq 0 ]; then
    process_dir "$start_dir"
else
    dirs=()
    files=()
    for path in "$@"; do
        if [ -d "$path" ]; then
            dirs+=("$path")
        elif [ -f "$path" ]; then
            # Skip binary files directly in param list
            if ! file --mime "$path" | grep -q 'charset=binary'; then
                files+=("$path")
            fi
        fi
    done

    if [ ${#dirs[@]} -eq 1 ] && [ ${#files[@]} -eq 0 ]; then
        process_dir "${dirs[0]}"
    elif [ ${#dirs[@]} -eq 0 ] && [ ${#files[@]} -eq 1 ]; then
        process_file "${files[0]}"
    else
        for item in "$@"; do
            echo
            echo "--------------------------------------------------"
            echo
            if [ -d "$item" ]; then
                process_dir "$item"
            elif [ -f "$item" ]; then
                process_file "$item"
            fi
        done
    fi
fi
