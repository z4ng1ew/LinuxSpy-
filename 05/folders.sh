#!/usr/bin/env bash

analyze_folders() {
    local target_dir="$1"

    local folder_count
    folder_count=$(find "$target_dir" -type d 2>/dev/null | wc -l)
    echo "Total number of folders (including all nested ones) = $folder_count"

    echo "TOP 5 folders of maximum size arranged in descending order (path and size):"
    find "$target_dir" -type d 2>/dev/null | while read -r dir; do
        size_bytes=$(du -sb "$dir" 2>/dev/null | awk '{print $1}')
        echo "$size_bytes|$dir"
    done | sort -t'|' -k1 -rn | head -5 | while IFS='|' read -r size_bytes path; do
        size_human=$(bytes_to_human "$size_bytes")

        if [[ ! "$path" =~ /$ ]]; then
            path="${path}/"
        fi
        echo "$path|$size_human"
    done | awk -F'|' '{print NR " - " $1 ", " $2}'
}