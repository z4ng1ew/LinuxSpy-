#!/usr/bin/env bash










set -euo pipefail

trap 'echo -e "\n\nПрервано пользователем."; exit 130' INT TERM

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



    local node_name
    node_name=$(hostname -s 2>/dev/null || hostname)

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
        uptime_seconds=$(awk '{printf "%.0f", $1}' /proc/uptime)
        
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
            
            # Расчёт маски через битовые операции
            mask = 0;
            for (i = 0; i < prefix; i++) {
                mask = mask * 2 + 1;
            }
            for (i = prefix; i < 32; i++) {
                mask = mask * 2;
            }
            
            # Извлечение октетов
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























    cat <<EOF
HOSTNAME = $node_name
TIMEZONE = $tz_name UTC $tz_offset
USER = $active_user
OS = $os_release
DATE = $current_moment
UPTIME = $uptime_human
UPTIME_SEC = ${uptime_seconds} seconds
IP = $machine_ip
MASK = $subnet_mask
GATEWAY = $default_gateway
RAM_TOTAL = ${ram_total_gb} GB
RAM_USED = ${ram_used_gb} GB
RAM_FREE = ${ram_free_gb} GB
SPACE_ROOT = ${root_total_mb} MB
SPACE_ROOT_USED = ${root_used_mb} MB
SPACE_ROOT_FREE = ${root_free_mb} MB
EOF
}















prompt_persistence() {
    local facts_snapshot="$1"
    
    while true; do
        read -rp "Сохранить результат в файл? (Y/N): " user_choice
        
        user_choice=$(echo "$user_choice" | tr '[:upper:]' '[:lower:]')
        
        case "$user_choice" in
            y|yes)
                local timestamp report_name
                timestamp=$(date +"%d_%m_%y_%H_%M_%S")
                report_name="${timestamp}.status"
                
                if echo "$facts_snapshot" > "$report_name" 2>/dev/null; then
                    echo -e "\nОтчёт сохранён: $report_name"
                    return 0
                else
                    echo -e "\nОшибка: не удалось сохранить файл в текущей директории" >&2
                    return 1
                fi
                ;;
            n|no)
                echo -e "\nДанные не будут сохранены."
                return 0
                ;;
            *)
                echo "Некорректный ввод. Используйте Y или N."
                ;;
        esac
    done
}
























main() {
    check_dependencies
    
    local system_report
    system_report=$(gather_system_facts)
    
    echo -e "\n=== СИСТЕМНАЯ СВОДКА ==="
    echo "$system_report"
    echo "======================="
    
    prompt_persistence "$system_report"
}

main "$@"
