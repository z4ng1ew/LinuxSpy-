#!/usr/bin/env bash
set -euo pipefail # Строгий режим

# Определяем папку скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === БЛОК 1: ИМПОРТЫ ===
# Загружаем "мозги" из всех соседних файлов
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/collector.sh"
source "$SCRIPT_DIR/output.sh"

trap 'echo -e "\n\nПрервано пользователем."; exit 130' INT TERM

main() {
    # 1. Проверяем инструменты (ip, awk...)
    check_dependencies
    
    # === БЛОК 2: ЗАГРУЗКА И ЧТЕНИЕ КОНФИГА ===
    # Создаем пустые переменные, куда положим данные
    local col1_bg col1_fg col2_bg col2_fg
    local col1_bg_def col1_fg_def col2_bg_def col2_fg_def
    
    # МАГИЯ: < <(load_config) — Это "Подстановка процесса" (Process Substitution).
    # 1. Запускается функция load_config.
    # 2. Она делает echo "6 1 2 4 1 1 1 1".
    # 3. Этот вывод превращается во временный файловый поток.
    # 4. Команда read считывает этот поток и раскладывает 8 чисел по 8 переменным.
    read -r col1_bg col1_fg col2_bg col2_fg col1_bg_def col1_fg_def col2_bg_def col2_fg_def < <(load_config)
    
    # 3. Красивый заголовок
    echo -e "\n=== СИСТЕМНАЯ СВОДКА ==="
    
    # 4. Запускаем Сыщика (collector.sh), передавая ему ТОЛЬКО цвета (4 аргумента)
    gather_system_facts "$col1_bg" "$col1_fg" "$col2_bg" "$col2_fg"
    
    echo "======================="
    
    # 5. Запускаем Репортера (output.sh), передавая ему ВСЕ данные (цвета + флаги дефолта)
    echo ""
    print_color_scheme "$col1_bg" "$col1_fg" "$col2_bg" "$col2_fg" "$col1_bg_def" "$col1_fg_def" "$col2_bg_def" "$col2_fg_def"
}

# Старт!
main "$@"