#!/bin/bash

# Starting directory and its name
start_dir="$(pwd)"
root_name="$(basename "$start_dir")"

# Draw directory tree without using `tree` command
print_tree() {
    local dir="$1"
    local prefix="$2"

    # Collect entries (skip hidden directories and hidden files)
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

# Output: tree
echo "${root_name}/"
print_tree "$start_dir" ""

# Output: files with content
find "$start_dir" \
    \( -path '*/.*' -prune \) -o \
    -type f -print0 | sort -z |
while IFS= read -r -d '' file; do
    rel_path="${file#$start_dir/}"
    echo "${root_name}/${rel_path}"

    ext="${file##*.}"
    lang="$(get_lang "$ext")"

    if [ -n "$lang" ]; then
        printf '```%s\n' "$lang"
    else
        echo '```'
    fi

    cat "$file"
    echo
    echo '```'
done

