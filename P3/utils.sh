#!/usr/bin/env bash

check_dependencies() {
    local missing=()
    for cmd in ip awk free df date hostname; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Ошибка: отсутствуют команды: ${missing[*]}" >&2
        exit 1
    fi
}