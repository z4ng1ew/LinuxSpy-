#!/bin/bash

# Название выходного текстового документа
OUTPUT_FILE="all_contents.txt"

# Очищаем выходной файл или создаем новый
> "$OUTPUT_FILE"

echo "Начинаю сбор содержимого всех файлов..."

# Рекурсивно обходим все файлы в текущей директории и поддиректориях
find . -type f ! -name "$OUTPUT_FILE" | while read -r file; do
    # Добавляем заголовок с путем к файлу
    echo "=== ФАЙЛ: $file ===" >> "$OUTPUT_FILE"
    echo "Путь: $(realpath "$file")" >> "$OUTPUT_FILE"
    echo "Размер: $(du -h "$file" | cut -f1)" >> "$OUTPUT_FILE"
    echo "Дата изменения: $(stat -c %y "$file" 2>/dev/null || date -r "$file")" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Добавляем содержимое файла
    echo "СОДЕРЖИМОЕ:" >> "$OUTPUT_FILE"
    echo "----------------------------------------" >> "$OUTPUT_FILE"
    
    if [[ -r "$file" ]]; then
        # Пробуем прочитать файл как текстовый
        if file "$file" | grep -q "text"; then
            # Для текстовых файлов
            cat "$file" >> "$OUTPUT_FILE" 2>/dev/null || echo "[Не удалось прочитать файл]" >> "$OUTPUT_FILE"
        else
            # Для бинарных или специальных файлов
            echo "[Бинарный файл или неподдерживаемый формат]" >> "$OUTPUT_FILE"
            echo "[Информация о файле: $(file "$file")]" >> "$OUTPUT_FILE"
        fi
    else
        echo "[Файл недоступен для чтения]" >> "$OUTPUT_FILE"
    fi
    
    echo -e "\n" >> "$OUTPUT_FILE"
    echo "========================================" >> "$OUTPUT_FILE"
    echo -e "\n\n" >> "$OUTPUT_FILE"
done

# Подсчитываем статистику
TOTAL_FILES=$(find . -type f ! -name "$OUTPUT_FILE" | wc -l)
TOTAL_DIRS=$(find . -type d | wc -l)
OUTPUT_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

# Добавляем сводку в начало файла
SUMMARY="СВОДНАЯ ИНФОРМАЦИЯ
Дата создания: $(date)
Всего директорий: $TOTAL_DIRS
Всего файлов: $TOTAL_FILES
Размер итогового документа: $OUTPUT_SIZE
========================================

"

# Вставляем сводку в начало файла
echo -e "$SUMMARY$(cat "$OUTPUT_FILE")" > "$OUTPUT_FILE.tmp"
mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"

echo "Готово!"
echo "Содержимое всех файлов сохранено в: $(realpath "$OUTPUT_FILE")"
echo "Обработано файлов: $TOTAL_FILES"
echo "Размер итогового файла: $OUTPUT_SIZE"
