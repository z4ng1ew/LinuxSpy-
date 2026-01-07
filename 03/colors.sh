#!/usr/bin/env bash

get_color() {
    local color_num=$1
    local is_background=$2
    
    case $color_num in
        1) 
            [[ $is_background -eq 1 ]] && echo "47" || echo "97"
            ;;
        2) 
            [[ $is_background -eq 1 ]] && echo "41" || echo "31"
            ;;
        3) 
            [[ $is_background -eq 1 ]] && echo "42" || echo "32"
            ;;
        4) 
            [[ $is_background -eq 1 ]] && echo "44" || echo "34"
            ;;
        5) 
            [[ $is_background -eq 1 ]] && echo "45" || echo "35"
            ;;
        6) 
            [[ $is_background -eq 1 ]] && echo "40" || echo "30"
            ;;
        *)
            echo ""
            ;;
    esac
}