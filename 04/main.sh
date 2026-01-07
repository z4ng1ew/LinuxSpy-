#!/usr/bin/env bash
set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/collector.sh"
source "$SCRIPT_DIR/output.sh"

trap 'echo -e "\n\nПрервано пользователем."; exit 130' INT TERM

main() {

    check_dependencies
    
    local col1_bg col1_fg col2_bg col2_fg
    local col1_bg_def col1_fg_def col2_bg_def col2_fg_def
    
    read -r col1_bg col1_fg col2_bg col2_fg col1_bg_def col1_fg_def col2_bg_def col2_fg_def < <(load_config)

    gather_system_facts "$col1_bg" "$col1_fg" "$col2_bg" "$col2_fg"


    echo ""
    print_color_scheme "$col1_bg" "$col1_fg" "$col2_bg" "$col2_fg" "$col1_bg_def" "$col1_fg_def" "$col2_bg_def" "$col2_fg_def"
}

main "$@"