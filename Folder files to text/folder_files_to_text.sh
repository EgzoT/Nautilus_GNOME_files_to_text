#!/bin/bash

# Current working directory
start_dir="$(pwd)"
root_name="$(basename "$start_dir")"

# Make a path relative to given base directory
rel_to_base() {
    local abs="$1"
    local base="$2"
    local rel=""

    if command -v realpath >/dev/null 2>&1; then
        rel="$(realpath --relative-to="$base" "$abs" 2>/dev/null || true)"
    fi
    if [ -z "$rel" ]; then
        case "$abs" in
            "$base"/*) rel="${abs#$base/}" ;;
            *) rel="$(basename "$abs")" ;;
        esac
    fi
    rel="${rel#./}"
    while [[ "$rel" == ../* ]]; do rel="${rel#../}"; done
    printf '%s' "$rel"
}

# Draw directory tree
print_tree() {
    local dir="$1"
    local prefix="$2"

    local entries=()
    while IFS= read -r -d '' name; do
        [[ "$name" == .* ]] && continue
        entries+=("$name")
    done < <(find "$dir" -mindepth 1 -maxdepth 1 \
                \( -path '*/.*' -prune \) -o \
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

# Language mapping
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

# Print file content
# mode: "file" -> just filename
#       "folder" -> basename(base_prefix)/relative-path-inside-that-folder
print_file_content() {
    local file="$1"
    local mode="$2"
    local base_prefix="$3"
    local header=""

    if [ "$mode" = "file" ]; then
        header="$(basename "$file")"
    else
        local base_name; base_name="$(basename "$base_prefix")"
        local rel_in_base; rel_in_base="$(rel_to_base "$file" "$base_prefix")"
        header="${base_name}/${rel_in_base}"
    fi

    echo "$header"
    local ext="${file##*.}"
    local lang="$(get_lang "$ext")"

    if [ -n "$lang" ]; then
        printf '```%s\n' "$lang"
    else
        echo '```'
    fi

    cat "$file"
    echo
    echo '```'
    echo
}

# Process folder: prints tree + files with paths relative to that folder
process_folder() {
    local dir="$1"
    echo "$(basename "$dir")/"
    print_tree "$dir" ""
    echo
    find "$dir" \
        \( -path '*/.*' -prune \) -o \
        -type f -print0 | sort -z |
    while IFS= read -r -d '' file; do
        print_file_content "$file" "folder" "$dir"
    done
}

# Main logic
if [ "$#" -eq 0 ]; then
    process_folder "$start_dir"
else
    folders=()
    files=()
    for arg in "$@"; do
        path="$start_dir/$arg"
        if [ -d "$path" ]; then
            folders+=("$path")
        elif [ -f "$path" ]; then
            files+=("$path")
        fi
    done

    if [ "${#folders[@]}" -eq 1 ] && [ "${#files[@]}" -eq 0 ]; then
        process_folder "${folders[0]}"
    elif [ "${#files[@]}" -eq 1 ] && [ "${#folders[@]}" -eq 0 ]; then
        print_file_content "${files[0]}" "file"
    elif [ "${#folders[@]}" -ge 2 ] && [ "${#files[@]}" -eq 0 ]; then
        for i in "${!folders[@]}"; do
            process_folder "${folders[$i]}"
            if [ "$i" -lt $(( ${#folders[@]} - 1 )) ]; then
                echo
                echo "--------------------------------------------------"
                echo
            fi
        done
    elif [ "${#files[@]}" -ge 2 ] && [ "${#folders[@]}" -eq 0 ]; then
        for i in "${!files[@]}"; do
            print_file_content "${files[$i]}" "file"
            if [ "$i" -lt $(( ${#files[@]} - 1 )) ]; then
                echo
                echo "--------------------------------------------------"
                echo
            fi
        done
    else
        mixed_items=("${folders[@]}" "${files[@]}")
        for i in "${!mixed_items[@]}"; do
            item="${mixed_items[$i]}"
            if [ -d "$item" ]; then
                process_folder "$item"
            elif [ -f "$item" ]; then
                print_file_content "$item" "file"
            fi
            if [ "$i" -lt $(( ${#mixed_items[@]} - 1 )) ]; then
                echo
                echo "--------------------------------------------------"
                echo
            fi
        done
    fi
fi
