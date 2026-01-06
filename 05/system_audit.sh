#!/bin/bash

START_TIME=$(date +%s.%N)

if [ $# -ne 1 ]; then
    echo "Usage: $0 <directory_path>"
    echo "Example: $0 /var/log/"
    exit 1
fi

TARGET_DIR="$1"


if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist"
    exit 1
fi


if [[ ! "$TARGET_DIR" =~ /$ ]]; then
    echo "Error: Directory path must end with '/'"
    echo "Example: $0 ${TARGET_DIR}/"
    exit 1
fi

echo "Analyzing directory: $TARGET_DIR"
echo "Please wait..."
echo


bytes_to_human() {
    local bytes=$1
    local gb=$((bytes / 1024 / 1024 / 1024))
    local mb=$((bytes / 1024 / 1024))
    local kb=$((bytes / 1024))
    
    if [ $gb -gt 0 ]; then
        echo "${gb} GB"
    elif [ $mb -gt 0 ]; then
        echo "${mb} MB"
    elif [ $kb -gt 0 ]; then
        echo "${kb} KB"
    else
        echo "${bytes} bytes"
    fi
}


FOLDER_COUNT=$(find "$TARGET_DIR" -type d 2>/dev/null | wc -l)
echo "Total number of folders (including all nested ones) = $FOLDER_COUNT"


echo "TOP 5 folders of maximum size arranged in descending order (path and size):"
find "$TARGET_DIR" -type d 2>/dev/null | while read -r dir; do
    size_bytes=$(du -sb "$dir" 2>/dev/null | awk '{print $1}')
    echo "$size_bytes|$dir"
done | sort -t'|' -k1 -rn | head -5 | while IFS='|' read -r size_bytes path; do
    size_human=$(bytes_to_human "$size_bytes")

    if [[ ! "$path" =~ /$ ]]; then
        path="${path}/"
    fi
    echo "$path|$size_human"
done | awk -F'|' '{print NR " - " $1 ", " $2}'


TOTAL_FILES=$(find "$TARGET_DIR" -type f 2>/dev/null | wc -l)
echo "Total number of files = $TOTAL_FILES"

echo "Number of:"


CONF_COUNT=$(find "$TARGET_DIR" -type f -name "*.conf" 2>/dev/null | wc -l)
echo "Configuration files (with the .conf extension) = $CONF_COUNT"


TEXT_COUNT=$(find "$TARGET_DIR" -type f -name "*.txt" 2>/dev/null | wc -l)
echo "Text files = $TEXT_COUNT"


EXEC_COUNT=$(find "$TARGET_DIR" -type f -executable 2>/dev/null | wc -l)
echo "Executable files = $EXEC_COUNT"


LOG_COUNT=$(find "$TARGET_DIR" -type f -name "*.log" 2>/dev/null | wc -l)
echo "Log files (with the extension .log) = $LOG_COUNT"


ARCHIVE_COUNT=$(find "$TARGET_DIR" -type f \( -name "*.zip" -o -name "*.tar" -o -name "*.gz" -o -name "*.bz2" -o -name "*.xz" -o -name "*.7z" -o -name "*.rar" -o -name "*.tar.gz" -o -name "*.tgz" \) 2>/dev/null | wc -l)
echo "Archive files = $ARCHIVE_COUNT"


SYMLINK_COUNT=$(find "$TARGET_DIR" -type l 2>/dev/null | wc -l)
echo "Symbolic links = $SYMLINK_COUNT"


echo "TOP 10 files of maximum size arranged in descending order (path, size and type):"
find "$TARGET_DIR" -type f 2>/dev/null -printf "%s|%p\n" | sort -t'|' -k1 -rn | head -10 | while IFS='|' read -r size_bytes path; do
    size_human=$(bytes_to_human "$size_bytes")
    

    type="unknown"
    basename_file=$(basename "$path")
    
    case "$path" in
        *.conf) type="conf" ;;
        *.txt) type="text" ;;
        *.log) type="log" ;;
        *.journal) type="journal" ;;
        *.zip|*.tar|*.gz|*.bz2|*.xz|*.7z|*.rar|*.tar.gz|*.tgz) type="archive" ;;
        *.exe) type="exe" ;;
        *.sh|*.bash) type="script" ;;
        *.bin) type="binary" ;;
        *.so|*.so.*) type="library" ;;
        *.deb|*.rpm) type="package" ;;
        *)

            case "$basename_file" in
                syslog*|messages*|daemon*|auth*|kern*|debug*|mail*|user*|cron*) type="log" ;;
            esac
            

            if [ "$type" = "unknown" ] && [ -x "$path" ]; then
                type="executable"
            fi
            ;;
    esac
    
    echo "$path|$size_human|$type"
done | awk -F'|' '{print NR " - " $1 ", " $2 ", " $3}'


echo "TOP 10 executable files of the maximum size arranged in descending order (path, size and MD5 hash of file):"
find "$TARGET_DIR" -type f -executable 2>/dev/null -printf "%s|%p\n" | sort -t'|' -k1 -rn | head -10 | while IFS='|' read -r size_bytes path; do
    size_human=$(bytes_to_human "$size_bytes")
    

    if command -v md5sum &> /dev/null; then
        hash=$(md5sum "$path" 2>/dev/null | awk '{print $1}')
    elif command -v md5 &> /dev/null; then
        hash=$(md5 -q "$path" 2>/dev/null)
    else
        hash="unavailable"
    fi
    
    [ -z "$hash" ] && hash="unavailable"
    
    echo "$path|$size_human|$hash"
done | awk -F'|' '{print NR " - " $1 ", " $2 ", " $3}'

END_TIME=$(date +%s.%N)


EXECUTION_TIME=$(echo "$END_TIME - $START_TIME" | bc 2>/dev/null)

if [[ -z "$EXECUTION_TIME" ]] || [[ "$EXECUTION_TIME" =~ ^\. ]]; then
    EXECUTION_TIME="0$EXECUTION_TIME"
fi

echo "Script execution time (in seconds) = $EXECUTION_TIME"