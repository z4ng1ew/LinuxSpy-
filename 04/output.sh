#!/usr/bin/env bash

print_color_scheme() {
    local col1_bg=$1
    local col1_fg=$2
    local col2_bg=$3
    local col2_fg=$4
    local col1_bg_is_default=$5
    local col1_fg_is_default=$6
    local col2_bg_is_default=$7
    local col2_fg_is_default=$8
    
    print_line() {
        local name=$1
        local val=$2
        local is_def=$3
        local color_name
        color_name=$(get_color_name "$val")
        
        if [[ $is_def -eq 1 ]]; then
            echo "$name = default ($color_name)"
        else
            echo "$name = $val ($color_name)"
        fi
    }

    print_line "Column 1 background" "$col1_bg" "$col1_bg_is_default"
    print_line "Column 1 font color" "$col1_fg" "$col1_fg_is_default"
    print_line "Column 2 background" "$col2_bg" "$col2_bg_is_default"
    print_line "Column 2 font color" "$col2_fg" "$col2_fg_is_default"
}