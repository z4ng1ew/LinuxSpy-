#!/usr/bin/env bash

set -euo pipefail

trap 'echo -e "\n\nПрервано пользователем."; exit 130' INT TERM

CONFIG_FILE="config.conf"

DEFAULT_COLUMN1_BG=6
DEFAULT_COLUMN1_FG=1
DEFAULT_COLUMN2_BG=2
DEFAULT_COLUMN2_FG=4

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

get_color_name() {
    case $1 in
        1) echo "white" ;;
        2) echo "red" ;;
        3) echo "green" ;;
        4) echo "blue" ;;
        5) echo "purple" ;;
        6) echo "black" ;;
        *) echo "unknown" ;;
    esac
}

load_config() {
    local col1_bg=$DEFAULT_COLUMN1_BG
    local col1_fg=$DEFAULT_COLUMN1_FG
    local col2_bg=$DEFAULT_COLUMN2_BG
    local col2_fg=$DEFAULT_COLUMN2_FG
    
    local col1_bg_is_default=1
    local col1_fg_is_default=1
    local col2_bg_is_default=1
    local col2_fg_is_default=1
    
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS='=' read -r key value; do
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            
            key=$(echo "$key" | tr -d '[:space:]')
            value=$(echo "$value" | tr -d '[:space:]')
            
            if [[ "$value" =~ ^[1-6]$ ]]; then
                case "$key" in
                    column1_background)
                        col1_bg=$value
                        col1_bg_is_default=0
                        ;;
                    column1_font_color)
                        col1_fg=$value
                        col1_fg_is_default=0
                        ;;
                    column2_background)
                        col2_bg=$value
                        col2_bg_is_default=0
                        ;;
                    column2_font_color)
                        col2_fg=$value
                        col2_fg_is_default=0
                        ;;
                esac
            fi
        done < "$CONFIG_FILE"
    fi
    
    if [[ $col1_bg -eq $col1_fg ]]; then
        echo "Ошибка: цвет фона и цвет шрифта для названий не должны совпадать."
        echo "Column 1 background = $col1_bg, Column 1 font color = $col1_fg"
        echo "Пожалуйста, измените конфигурационный файл."
        exit 1
    fi
    
    if [[ $col2_bg -eq $col2_fg ]]; then
        echo "Ошибка: цвет фона и цвет шрифта для значений не должны совпадать."
        echo "Column 2 background = $col2_bg, Column 2 font color = $col2_fg"
        echo "Пожалуйста, измените конфигурационный файл."
        exit 1
    fi
    
    echo "$col1_bg $col1_fg $col2_bg $col2_fg $col1_bg_is_default $col1_fg_is_default $col2_bg_is_default $col2_fg_is_default"
}

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

gather_system_facts() {
    set +e
    
    local bg_name=$1
    local fg_name=$2
    local bg_value=$3
    local fg_value=$4
    
    local color_bg_name color_fg_name color_bg_value color_fg_value
    color_bg_name=$(get_color "$bg_name" 1)
    color_fg_name=$(get_color "$fg_name" 0)
    color_bg_value=$(get_color "$bg_value" 1)
    color_fg_value=$(get_color "$fg_value" 0)
    
    local reset="\033[0m"
    local name_style="\033[${color_bg_name};${color_fg_name}m"
    local value_style="\033[${color_bg_value};${color_fg_value}m"

    local node_name
    node_name=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "Unknown")

    local tz_name tz_offset
    if command -v timedatectl &>/dev/null && timedatectl status &>/dev/null; then
        tz_name=$(timedatectl show --value --property=Timezone 2>/dev/null)
        [[ -z "$tz_name" ]] && tz_name="UTC"
        tz_offset=$(date +"%:::z" 2>/dev/null || date +"%z" | sed 's/\([+-][0-9][0-9]\).*/\1/' | sed 's/0\([0-9]\)/\1/')
    else
        tz_name="UTC"
        tz_offset="0"
    fi

    local active_user
    active_user=$(whoami)

    local os_release
    if command -v hostnamectl &>/dev/null && hostnamectl status &>/dev/null; then
        os_release=$(hostnamectl | awk -F': ' '/Operating System/ {print $2; exit}')
    elif command -v lsb_release &>/dev/null; then
        os_release=$(lsb_release -d 2>/dev/null | cut -f2)
    else
        os_release=$(uname -s 2>/dev/null || echo "Unknown")
    fi

    local current_moment
    current_moment=$(LC_TIME=C date +"%d %b %Y %H:%M:%S" | sed 's/^0//')

    local uptime_human uptime_seconds
    if [[ -f /proc/uptime ]]; then
        uptime_seconds=$(awk '{printf "%.0f", $1}' /proc/uptime 2>/dev/null || echo "0")
        
        local days hours mins
        days=$((uptime_seconds / 86400))
        hours=$(((uptime_seconds % 86400) / 3600))
        mins=$(((uptime_seconds % 3600) / 60))
        
        uptime_human=""
        if [[ $days -gt 0 ]]; then
            [[ $days -eq 1 ]] && uptime_human="${days} day" || uptime_human="${days} days"
            uptime_human+=", "
        fi
        [[ $hours -eq 1 ]] && uptime_human+="${hours} hour" || uptime_human+="${hours} hours"
        uptime_human+=", "
        [[ $mins -eq 1 ]] && uptime_human+="${mins} minute" || uptime_human+="${mins} minutes"
    else
        uptime_seconds="N/A"
        uptime_human="N/A"
    fi

    local main_iface
    main_iface=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}' || echo "eth0")

    local machine_ip subnet_mask default_gateway
    machine_ip=$(ip -4 addr show dev "$main_iface" 2>/dev/null | awk '/inet/ {print $2; exit}' | cut -d'/' -f1)
    [[ -z "$machine_ip" ]] && machine_ip="N/A"

    local cidr_prefix
    cidr_prefix=$(ip -4 addr show dev "$main_iface" 2>/dev/null | awk '/inet/ {print $2; exit}' | cut -d'/' -f2)
    
    if [[ -n "$cidr_prefix" ]]; then
        subnet_mask=$(awk -v prefix="$cidr_prefix" 'BEGIN {
            if (prefix == "" || prefix < 0 || prefix > 32) {
                print "N/A";
                exit;
            }
            
            mask = 0;
            for (i = 0; i < prefix; i++) {
                mask = mask * 2 + 1;
            }
            for (i = prefix; i < 32; i++) {
                mask = mask * 2;
            }
            
            octet1 = int(mask / 16777216) % 256;
            octet2 = int(mask / 65536) % 256;
            octet3 = int(mask / 256) % 256;
            octet4 = mask % 256;
            
            printf "%d.%d.%d.%d", octet1, octet2, octet3, octet4;
        }')
    else
        subnet_mask="N/A"
    fi

    default_gateway=$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')
    [[ -z "$default_gateway" ]] && default_gateway="N/A"

    local ram_total_gb ram_used_gb ram_free_gb
    if command -v free &>/dev/null; then
        read -r ram_total_gb ram_used_gb ram_free_gb < <(
            LC_ALL=C free -b | awk '/Mem:/ {
                total = $2 / 1024 / 1024 / 1024;
                used  = $3 / 1024 / 1024 / 1024;
                free_m = $4 / 1024 / 1024 / 1024;
                printf "%.3f %.3f %.3f", total, used, free_m
            }'
        )
    else
        ram_total_gb="N/A"
        ram_used_gb="N/A"
        ram_free_gb="N/A"
    fi

    local root_total_mb root_used_mb root_free_mb
    if command -v df &>/dev/null; then
        read -r root_total_mb root_used_mb root_free_mb < <(
            df -B1 / 2>/dev/null | awk 'NR==2 {
                total = $2/1024/1024;
                used = $3/1024/1024;
                free = $4/1024/1024;
                printf "%.2f %.2f %.2f", total, used, free
            }'
        )
    else
        root_total_mb="N/A"
        root_used_mb="N/A"
        root_free_mb="N/A"
    fi

    echo -e "${name_style}HOSTNAME${reset} = ${value_style}$node_name${reset}"
    echo -e "${name_style}TIMEZONE${reset} = ${value_style}$tz_name UTC $tz_offset${reset}"
    echo -e "${name_style}USER${reset} = ${value_style}$active_user${reset}"
    echo -e "${name_style}OS${reset} = ${value_style}$os_release${reset}"
    echo -e "${name_style}DATE${reset} = ${value_style}$current_moment${reset}"
    echo -e "${name_style}UPTIME${reset} = ${value_style}$uptime_human${reset}"
    echo -e "${name_style}UPTIME_SEC${reset} = ${value_style}${uptime_seconds} seconds${reset}"
    echo -e "${name_style}IP${reset} = ${value_style}$machine_ip${reset}"
    echo -e "${name_style}MASK${reset} = ${value_style}$subnet_mask${reset}"
    echo -e "${name_style}GATEWAY${reset} = ${value_style}$default_gateway${reset}"
    echo -e "${name_style}RAM_TOTAL${reset} = ${value_style}${ram_total_gb} GB${reset}"
    echo -e "${name_style}RAM_USED${reset} = ${value_style}${ram_used_gb} GB${reset}"
    echo -e "${name_style}RAM_FREE${reset} = ${value_style}${ram_free_gb} GB${reset}"
    echo -e "${name_style}SPACE_ROOT${reset} = ${value_style}${root_total_mb} MB${reset}"
    echo -e "${name_style}SPACE_ROOT_USED${reset} = ${value_style}${root_used_mb} MB${reset}"
    echo -e "${name_style}SPACE_ROOT_FREE${reset} = ${value_style}${root_free_mb} MB${reset}"
    
    set -e
}

print_color_scheme() {
    local col1_bg=$1
    local col1_fg=$2
    local col2_bg=$3
    local col2_fg=$4
    local col1_bg_is_default=$5
    local col1_fg_is_default=$6
    local col2_bg_is_default=$7
    local col2_fg_is_default=$8
    
    if [[ $col1_bg_is_default -eq 1 ]]; then
        echo "Column 1 background = default ($(get_color_name $col1_bg))"
    else
        echo "Column 1 background = $col1_bg ($(get_color_name $col1_bg))"
    fi
    
    if [[ $col1_fg_is_default -eq 1 ]]; then
        echo "Column 1 font color = default ($(get_color_name $col1_fg))"
    else
        echo "Column 1 font color = $col1_fg ($(get_color_name $col1_fg))"
    fi
    
    if [[ $col2_bg_is_default -eq 1 ]]; then
        echo "Column 2 background = default ($(get_color_name $col2_bg))"
    else
        echo "Column 2 background = $col2_bg ($(get_color_name $col2_bg))"
    fi
    
    if [[ $col2_fg_is_default -eq 1 ]]; then
        echo "Column 2 font color = default ($(get_color_name $col2_fg))"
    else
        echo "Column 2 font color = $col2_fg ($(get_color_name $col2_fg))"
    fi
}

main() {
    check_dependencies
    
    read -r col1_bg col1_fg col2_bg col2_fg col1_bg_is_default col1_fg_is_default col2_bg_is_default col2_fg_is_default < <(load_config)
    
    echo -e "\n=== СИСТЕМНАЯ СВОДКА ==="
    gather_system_facts "$col1_bg" "$col1_fg" "$col2_bg" "$col2_fg"
    echo "======================="
    
    echo ""
    print_color_scheme "$col1_bg" "$col1_fg" "$col2_bg" "$col2_fg" "$col1_bg_is_default" "$col1_fg_is_default" "$col2_bg_is_default" "$col2_fg_is_default"
}


main "$@"