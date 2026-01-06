#!/usr/bin/env bash
set -euo pipefail

validate_whisper() {
    local enchanted_word="$1"
    
    if [[ -z "$enchanted_word" ]]; then
        echo "error: заклинание не может быть пустым." >&2
        return 1
    fi
    
    if [[ "$enchanted_word" =~ ^[+-]?[0-9]+(\.[0-9]+)?$ ]]; then
        echo "error: заклинание не должно быть числом." >&2
        return 1
    fi
    
    return 0
}