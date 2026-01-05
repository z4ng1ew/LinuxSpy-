#!/usr/bin/env bash

# ОШИБКА БЫЛА ЗДЕСЬ: Мы убрали 'local', так как это основной код скрипта, а не функция.
# Просто объявляем переменные.
ram_total_gb=""
ram_used_gb=""
ram_free_gb=""

# Проверяем наличие утилиты 'free'
if command -v free &>/dev/null; then
    
    # Конструкция подстановки процесса для сохранения данных в текущем окружении
    read -r ram_total_gb ram_used_gb ram_free_gb < <(
        
        # LC_ALL=C гарантирует английский вывод "Mem:" для корректной работы awk
        # free -b дает точность до байта
        LC_ALL=C free -b | awk '/Mem:/ {
            # Конвертируем байты в Гб (деление на 1024 в третьей степени)
            total = $2 / 1024 / 1024 / 1024;
            used  = $3 / 1024 / 1024 / 1024;
            # Берем колонку $4 (Free) строго по заданию Школы 21
            free_m = $4 / 1024 / 1024 / 1024;
            
            # Выводим результат с точностью 3 знака после запятой
            printf "%.3f %.3f %.3f", total, used, free_m
        }'
    )
else
    ram_total_gb="N/A"
    ram_used_gb="N/A"
    ram_free_gb="N/A"
fi

# Выводим результат, чтобы убедиться, что всё работает
echo "RAM_TOTAL = $ram_total_gb GB"
echo "RAM_USED = $ram_used_gb GB"
echo "RAM_FREE = $ram_free_gb GB"