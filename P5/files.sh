#!/usr/bin/env bash

# === ФУНКЦИЯ 1: СТАТИСТИКА ПО ТИПАМ ===
count_file_types() {
    local target_dir="$1"
    
    # Просто считаем все файлы (-type f)
    local total_files
    total_files=$(find "$target_dir" -type f 2>/dev/null | wc -l)
    echo "Total number of files = $total_files"

    # ... (пропуск однотипных блоков с .conf, .txt) ...

    # Ищем архивы.
    # \( ... -o ... \): Группировка условий.
    # -o: Логическое ИЛИ (OR). Найти zip ИЛИ tar ИЛИ gz...
    local archive_count
    archive_count=$(find "$target_dir" -type f \( -name "*.zip" -o -name "*.tar" -o ... \) 2>/dev/null | wc -l)
    
    # Ищем символические ссылки (-type l)
    local symlink_count
    symlink_count=$(find "$target_dir" -type l 2>/dev/null | wc -l)
}

# === ФУНКЦИЯ 2: ТОП 10 ФАЙЛОВ ===
get_top_10_files() {
    local target_dir="$1"
    
    # ХИТРОСТЬ FIND:
    # -printf "%s|%p\n": Find умеет сам печатать размер (%s) и путь (%p).
    # Это работает быстрее, чем вызов 'du' для каждого файла.
    find "$target_dir" -type f 2>/dev/null -printf "%s|%p\n" | \
    sort -t'|' -k1 -rn | head -10 | while IFS='|' read -r size_bytes path; do
        
        # Конвертируем размер в человеческий вид
        size_human=$(bytes_to_human "$size_bytes")
        
        # ОПРЕДЕЛЕНИЕ ТИПА ФАЙЛА
        local type="unknown"
        # basename: отрезает путь, оставляя только имя файла (var/log/syslog -> syslog)
        local basename_file
        basename_file=$(basename "$path")
        
        # case "$path" in ... : Смотрим на расширение файла
        case "$path" in
            *.conf) type="conf" ;;
            *.txt) type="text" ;;
            # ...
            *)
                # Если расширения нет, смотрим на имя файла
                case "$basename_file" in
                    syslog*|messages*) type="log" ;; # Логи часто без расширения
                esac
                
                # Если тип все еще unknown, но файл исполняемый (-x), помечаем как executable
                if [ "$type" = "unknown" ] && [ -x "$path" ]; then
                    type="executable"
                fi
                ;;
        esac
        
        echo "$path|$size_human|$type"
    done | awk -F'|' '{print NR " - " $1 ", " $2 ", " $3}'
}

# === ФУНКЦИЯ 3: ТОП 10 ИСПОЛНЯЕМЫХ (С ХЕШЕМ) ===
get_top_10_executables() {
    # Ищем только исполняемые файлы (-executable)
    find "$target_dir" -type f -executable ... | ... | while ...; do
        
        # ВЫЧИСЛЕНИЕ MD5 ХЕША
        local hash
        # command -v: Проверяем, какая программа для хешей установлена
        if command -v md5sum &> /dev/null; then
            # md5sum (Linux стандарт)
            hash=$(md5sum "$path" 2>/dev/null | awk '{print $1}')
        elif command -v md5 &> /dev/null; then
            # md5 (BSD/MacOS стандарт)
            hash=$(md5 -q "$path" 2>/dev/null)
        else
            hash="unavailable"
        fi
        
        echo "$path|$size_human|$hash"
    done ...
}