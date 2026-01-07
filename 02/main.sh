#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/collector.sh"
source "$SCRIPT_DIR/io.sh"

trap 'echo -e "\n\nПрервано пользователем."; exit 130' INT TERM

main() {
    check_dependencies
    
    local system_report
    system_report=$(gather_system_facts)
    
    echo "$system_report"
    
    prompt_persistence "$system_report"
}

main "$@"