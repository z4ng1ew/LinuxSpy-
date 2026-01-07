#!/usr/bin/env bash

gather_system_facts() {
    # Временно отключаем exit on error, чтобы одна упавшая команда не ломала весь отчет
    set +e
    
    local bg_name=$1
    local fg_name=$2
    local bg_value=$3
    local fg_value=$4
    
    # Получаем коды цветов через функцию из colors.sh
    local color_bg_name color_fg_name color_bg_value color_fg_value
    color_bg_name=$(get_color "$bg_name" 1)
    color_fg_name=$(get_color "$fg_name" 0)
    color_bg_value=$(get_color "$bg_value" 1)
    color_fg_value=$(get_color "$fg_value" 0)
    
    local reset="\033[0m"
    local name_style="\033[${color_bg_name};${color_fg_name}m"
    local value_style="\033[${color_bg_value};${color_fg_value}m"

    # --- Сбор данных ---
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
            if (prefix == "" || prefix < 0 || prefix > 32) { print "N/A"; exit; }
            mask = 0;
            for (i = 0; i < prefix; i++) { mask = mask * 2 + 1; }
            for (i = prefix; i < 32; i++) { mask = mask * 2; }
            printf "%d.%d.%d.%d", int(mask/16777216)%256, int(mask/65536)%256, int(mask/256)%256, mask%256;
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
                printf "%.3f %.3f %.3f", $2/1073741824, $3/1073741824, $4/1073741824
            }'
        )
    else
        ram_total_gb="N/A" ram_used_gb="N/A" ram_free_gb="N/A"
    fi

    local root_total_mb root_used_mb root_free_mb
    if command -v df &>/dev/null; then
        read -r root_total_mb root_used_mb root_free_mb < <(
            df -B1 / 2>/dev/null | awk 'NR==2 {
                printf "%.2f %.2f %.2f", $2/1048576, $3/1048576, $4/1048576
            }'
        )
    else
        root_total_mb="N/A" root_used_mb="N/A" root_free_mb="N/A"
    fi

    # --- Вывод данных с цветами ---
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
    
    # Возвращаем строгий режим
    set -e
}