#!/usr/bin/env bash

START_TIME=$(date +%s.%N)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/validation.sh"
source "$SCRIPT_DIR/folders.sh"
source "$SCRIPT_DIR/files.sh"

validate_input "$@"
TARGET_DIR="$1"



analyze_folders "$TARGET_DIR"

count_file_types "$TARGET_DIR"

get_top_10_files "$TARGET_DIR"

get_top_10_executables "$TARGET_DIR"


END_TIME=$(date +%s.%N)
EXECUTION_TIME=$(echo "$END_TIME - $START_TIME" | bc 2>/dev/null)

if [[ -z "$EXECUTION_TIME" ]] || [[ "$EXECUTION_TIME" =~ ^\. ]]; then
    EXECUTION_TIME="0$EXECUTION_TIME"
fi

echo "Script execution time (in seconds) = $EXECUTION_TIME"