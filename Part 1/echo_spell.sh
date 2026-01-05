#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/whisper_validator.sh"

if [[ $# -ne 1 ]]; then
    echo "error: требуется ровно одно заклинание." >&2
    exit 1
fi

validate_whisper "$1" || exit 1

echo "$1"