#!/usr/bin/env bash

count_file_types() {
    local target_dir="$1"
    
    local total_files
    total_files=$(find "$target_dir" -type f 2>/dev/null | wc -l)
    echo "Total number of files = $total_files"

    echo "Number of:"

    local conf_count
    conf_count=$(find "$target_dir" -type f -name "*.conf" 2>/dev/null | wc -l)
    echo "Configuration files (with the .conf extension) = $conf_count"

    local text_count
    text_count=$(find "$target_dir" -type f -name "*.txt" 2>/dev/null | wc -l)
    echo "Text files = $text_count"

    local exec_count
    exec_count=$(find "$target_dir" -type f -executable 2>/dev/null | wc -l)
    echo "Executable files = $exec_count"

    local log_count
    log_count=$(find "$target_dir" -type f -name "*.log" 2>/dev/null | wc -l)
    echo "Log files (with the extension .log) = $log_count"

    local archive_count
    archive_count=$(find "$target_dir" -type f \( -name "*.zip" -o -name "*.tar" -o -name "*.gz" -o -name "*.bz2" -o -name "*.xz" -o -name "*.7z" -o -name "*.rar" -o -name "*.tar.gz" -o -name "*.tgz" \) 2>/dev/null | wc -l)
    echo "Archive files = $archive_count"

    local symlink_count
    symlink_count=$(find "$target_dir" -type l 2>/dev/null | wc -l)
    echo "Symbolic links = $symlink_count"
}

get_top_10_files() {
    local target_dir="$1"
    
    echo "TOP 10 files of maximum size arranged in descending order (path, size and type):"
    find "$target_dir" -type f 2>/dev/null -printf "%s|%p\n" | sort -t'|' -k1 -rn | head -10 | while IFS='|' read -r size_bytes path; do
        size_human=$(bytes_to_human "$size_bytes")
        
        local type="unknown"
        local basename_file
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
}

get_top_10_executables() {
    local target_dir="$1"
    
    echo "TOP 10 executable files of the maximum size arranged in descending order (path, size and MD5 hash of file):"
    find "$target_dir" -type f -executable 2>/dev/null -printf "%s|%p\n" | sort -t'|' -k1 -rn | head -10 | while IFS='|' read -r size_bytes path; do
        size_human=$(bytes_to_human "$size_bytes")
        
        local hash
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
}