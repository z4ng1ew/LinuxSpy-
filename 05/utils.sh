#!/usr/bin/env bash

bytes_to_human() {
    local bytes=$1
    local gb=$((bytes / 1024 / 1024 / 1024))
    local mb=$((bytes / 1024 / 1024))
    local kb=$((bytes / 1024))
    
    if [ "$gb" -gt 0 ]; then
        echo "${gb} GB"
    elif [ "$mb" -gt 0 ]; then
        echo "${mb} MB"
    elif [ "$kb" -gt 0 ]; then
        echo "${kb} KB"
    else
        echo "${bytes} bytes"
    fi
}