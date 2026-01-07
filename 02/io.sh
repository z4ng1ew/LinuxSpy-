#!/usr/bin/env bash

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