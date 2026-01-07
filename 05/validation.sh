#!/usr/bin/env bash

validate_input() {
    if [ $# -ne 1 ]; then
        echo "Usage: $0 <directory_path>"
        echo "Example: $0 /var/log/"
        exit 1
    fi

    local target_dir="$1"

    if [ ! -d "$target_dir" ]; then
        echo "Error: Directory '$target_dir' does not exist"
        exit 1
    fi

    if [[ ! "$target_dir" =~ /$ ]]; then
        echo "Error: Directory path must end with '/'"
        echo "Example: $0 ${target_dir}/"
        exit 1
    fi
}