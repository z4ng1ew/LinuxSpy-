#!/usr/bin/env bash

# === БЛОК 1: СТАРТ ТАЙМЕРА ===
# Мы хотим засечь время с точностью до наносекунд.
# date +%s.%N:
#   %s — секунды с начала эпохи Unix (1970 год).
#   %N — наносекунды (добавляют огромную точность).
START_TIME=$(date +%s.%N)

# === БЛОК 2: ПОИСК СЕБЯ ===
# Эта магия нужна, чтобы скрипт знал, где лежат его файлы-друзья (modules),
# даже если вы запустили его из другой папки.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === БЛОК 3: ИМПОРТ МОДУЛЕЙ ===
# source — команда "вставь содержимое этого файла сюда".
# Теперь функции из этих файлов доступны нам так, будто они написаны здесь.
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/validation.sh"
source "$SCRIPT_DIR/folders.sh"
source "$SCRIPT_DIR/files.sh"

# === БЛОК 4: ВАЛИДАЦИЯ И ЗАПУСК ===
# Передаем все аргументы ($@) функции валидации.
validate_input "$@"

# Сохраняем путь к папке в переменную.
TARGET_DIR="$1"

# Вызываем функции из других файлов по очереди:
analyze_folders "$TARGET_DIR"       # Анализ папок (из folders.sh)
count_file_types "$TARGET_DIR"      # Подсчет типов (из files.sh)
get_top_10_files "$TARGET_DIR"      # Топ файлов (из files.sh)
get_top_10_executables "$TARGET_DIR" # Топ программ (из files.sh)

# === БЛОК 5: РАСЧЕТ ВРЕМЕНИ ===
END_TIME=$(date +%s.%N) # Фиксируем время конца

# Считаем разницу: Конец - Начало.
# bc — это калькулятор командной строки (Basic Calculator), 
# потому что Bash сам не умеет работать с дробными числами (с точкой).
EXECUTION_TIME=$(echo "$END_TIME - $START_TIME" | bc 2>/dev/null)

# Косметика: Если число начинается с точки (например, .45), добавляем нолик (0.45).
if [[ -z "$EXECUTION_TIME" ]] || [[ "$EXECUTION_TIME" =~ ^\. ]]; then
    EXECUTION_TIME="0$EXECUTION_TIME"
fi

echo "Script execution time (in seconds) = $EXECUTION_TIME"