local uptime_human uptime_seconds
if [[ -f /proc/uptime ]]; then
    # Читаем сырые данные
    uptime_seconds=$(awk '{printf "%.0f", $1}' /proc/uptime)
    echo "--- ОТЛАДКА 1: Всего секунд аптайма: $uptime_seconds ---"

    local days hours mins
    days=$((uptime_seconds / 86400))
    hours=$(((uptime_seconds % 86400) / 3600))
    mins=$(((uptime_seconds % 3600) / 60))
    
    echo "--- ОТЛАДКА 2: Рассчитано: Дней: $days, Часов: $hours, Минут: $mins ---"

    uptime_human=""
    
    # Сборка дней
    if [[ $days -gt 0 ]]; then
        [[ $days -eq 1 ]] && uptime_human="${days} day" || uptime_human="${days} days"
        uptime_human+=", "
        echo "--- ОТЛАДКА 3: Добавлены дни. Текущая строка: '$uptime_human' ---"
    fi
    
    # Сборка часов
    [[ $hours -eq 1 ]] && uptime_human+="${hours} hour" || uptime_human+="${hours} hours"
    echo "--- ОТЛАДКА 4: Добавлены часы. Текущая строка: '$uptime_human' ---"
    
    uptime_human+=", "
    
    # Сборка минут
    [[ $mins -eq 1 ]] && uptime_human+="${mins} minute" || uptime_human+="${mins} minutes"
    echo "--- ОТЛАДКА 5: Итоговая строка: '$uptime_human' ---"

else
    echo "--- ОТЛАДКА 6: Файл /proc/uptime не найден! ---"
    uptime_seconds="N/A"
    uptime_human="N/A"
fi



# ./TEST.SH: строка 1: local: можно использовать только внутри функции
# --- ОТЛАДКА: Всего секунд аптайма: 44473 ---
# ./TEST.SH: строка 7: local: можно использовать только внутри функции
# --- ОТЛАДКА: Рассчитано: Дней: 0, Часов: 12, Минут: 21 ---
# --- ОТЛАДКА: Добавлены часы. Текущая строка: '12 hours' ---
# --- ОТЛАДКА: Итоговая строка: '12 hours, 21 minutes' ---