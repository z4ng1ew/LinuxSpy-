#!/usr/bin/env bash

analyze_folders() {
    local target_dir="$1"

    # === ПОДСЧЕТ КОЛИЧЕСТВА ===
    # find -type d: Найти только директории.
    # wc -l: Посчитать количество строк (line count).
    local folder_count
    folder_count=$(find "$target_dir" -type d 2>/dev/null | wc -l)
    echo "Total number of folders (including all nested ones) = $folder_count"

    echo "TOP 5 folders..."
    
    # === СЛОЖНЫЙ КОНВЕЙЕР (PIPE) ===
    # 1. find: Находит все папки.
    # 2. while read -r dir: Перебирает папки по одной.
    #    Внутри цикла мы запускаем 'du' (Disk Usage) для каждой папки.
    #    -s (summary): общий вес папки. -b (bytes): в байтах.
    #    awk '{print $1}': оставляет только цифру размера.
    #    echo "$size_bytes|$dir": Печатает "РАЗМЕР|ПУТЬ".
    
    find "$target_dir" -type d 2>/dev/null | while read -r dir; do
        size_bytes=$(du -sb "$dir" 2>/dev/null | awk '{print $1}')
        echo "$size_bytes|$dir"
    done | \
    
    # 3. sort -t'|' -k1 -rn:
    #    -t'|': Разделитель колонок — вертикальная черта.
    #    -k1: Сортируем по 1-й колонке (размер).
    #    -r: Reverse (от большего к меньшему).
    #    -n: Numeric (считать как числа, а не как текст).
    sort -t'|' -k1 -rn | \
    
    # 4. head -5: Берем только первые 5.
    head -5 | \
    
    # 5. Финальное оформление
    #    Читаем строку "размер|путь", превращаем размер в GB/MB, 
    #    добавляем слеш если надо и нумеруем (NR в awk — номер строки).
    while IFS='|' read -r size_bytes path; do
        size_human=$(bytes_to_human "$size_bytes")

        if [[ ! "$path" =~ /$ ]]; then
            path="${path}/"
        fi
        echo "$path|$size_human"
    done | awk -F'|' '{print NR " - " $1 ", " $2}'
}