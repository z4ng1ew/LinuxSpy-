#!/usr/bin/env bash

validate_input() {
    # 1. Проверка количества аргументов
    # $# — число аргументов. -ne — "Not Equal" (не равно).
    if [ $# -ne 1 ]; then
        echo "Usage: $0 <directory_path>"
        exit 1
    fi

    local target_dir="$1"

    # 2. Проверка существования
    # -d — проверяет, является ли путь Директорией и существует ли она.
    if [ ! -d "$target_dir" ]; then
        echo "Error: Directory '$target_dir' does not exist"
        exit 1
    fi

    # 3. Проверка слеша в конце
    # =~ — оператор регулярных выражений (RegEx).
    # /$ — означает "символ / в самом конце строки".
    # ! — отрицание (ЕСЛИ НЕ заканчивается на слеш).
    if [[ ! "$target_dir" =~ /$ ]]; then
        echo "Error: Directory path must end with '/'"
        exit 1
    fi
}