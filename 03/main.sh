#!/usr/bin/env bash
set -euo pipefail

# Определяем директорию, где лежит скрипт, чтобы корректно импортировать модули
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Импортируем модули
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/validation.sh"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/collector.sh"

# Обработка прерывания
trap 'echo -e "\n\nПрервано пользователем."; exit 130' INT TERM

main() {
    # 1. Валидация входных параметров
    validate_parameters "$@"
    
    # 2. Проверка зависимостей
    check_dependencies
    
    # 3. Вывод заголовка

    
    # 4. Сбор фактов и вывод с цветами
    gather_system_facts "$1" "$2" "$3" "$4"
    

}

main "$@"