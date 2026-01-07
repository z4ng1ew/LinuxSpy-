#!/usr/bin/env bash

# === БЛОК 1: ПОИСК ФАЙЛА КОНФИГУРАЦИИ ===
# $(dirname "${BASH_SOURCE[0]}") — Магия определения пути. 
# Говорит: "Где бы я ни лежал, найди файл config.conf РЯДОМ со мной".
CONFIG_FILE="$(dirname "${BASH_SOURCE[0]}")/config.conf"

# Значения по умолчанию (если конфига нет или он пустой)
DEFAULT_COLUMN1_BG=6 # Черный фон
DEFAULT_COLUMN1_FG=1 # Белый текст
DEFAULT_COLUMN2_BG=2 # Красный фон
DEFAULT_COLUMN2_FG=4 # Синий текст

# === БЛОК 2: ФУНКЦИЯ ЗАГРУЗКИ ===
load_config() {
    # Инициализируем переменные дефолтными значениями
    local col1_bg=$DEFAULT_COLUMN1_BG
    local col1_fg=$DEFAULT_COLUMN1_FG
    local col2_bg=$DEFAULT_COLUMN2_BG
    local col2_fg=$DEFAULT_COLUMN2_FG
    
    # Флаги "по умолчанию" (1 = да, 0 = нет). Нужны для финального отчета.
    local col1_bg_is_default=1
    # ... (остальные флаги тоже 1) ...
    
    # Проверяем, существует ли файл (-f)
    if [[ -f "$CONFIG_FILE" ]]; then
        
        # === ЦИКЛ ЧТЕНИЯ ФАЙЛА ПОСТРОЧНО ===
        # IFS='=': Внутренний Разделитель Полей. Мы говорим команде read: "Разрезай строку там, где знак равно".
        # read -r key value: "Левую часть положи в переменную key, правую — в value".
        while IFS='=' read -r key value; do
            
            # 1. Пропускаем мусор:
            # -z "$key": Если ключ пустой (пустая строка).
            # ||: ИЛИ
            # =~ ^[[:space:]]*#: Если строка начинается с решетки (комментарий).
            # continue: "Пропусти этот круг цикла, иди к следующей строке".
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            
            # 2. Чистка от пробелов (tr -d '[:space:]'):
            # Если пользователь написал " column1_background = 6 ", tr удалит все пробелы.
            key=$(echo "$key" | tr -d '[:space:]')
            value=$(echo "$value" | tr -d '[:space:]')
            
            # 3. Проверка значения (валидация):
            # =~ ^[1-6]$: Значение должно быть ОДНОЙ цифрой от 1 до 6.
            if [[ "$value" =~ ^[1-6]$ ]]; then
                case "$key" in
                    column1_background) 
                        col1_bg=$value          # Присваиваем новое значение
                        col1_bg_is_default=0    # Ставим галочку "Это НЕ дефолт"
                        ;;
                    column1_font_color) 
                        col1_fg=$value; col1_fg_is_default=0 
                        ;;
                    # ... остальные переменные ...
                esac
            fi
        # < "$CONFIG_FILE": Это перенаправление ввода. Мы скармливаем файл циклу while.
        done < "$CONFIG_FILE"
    fi
    
    # === БЛОК 3: ПРОВЕРКА КОНТРАСТА (ВАЛИДАЦИЯ) ===
    # Если фон (bg) равен (-eq) шрифту (fg), читать будет невозможно.
    if [[ $col1_bg -eq $col1_fg ]]; then
        # >&2: Перенаправляем сообщение в поток ОШИБОК (stderr).
        echo "Ошибка: цвет фона и цвет шрифта совпадают." >&2
        exit 1 # Аварийный выход
    fi
    
    if [[ $col2_bg -eq $col2_fg ]]; then
        echo "Ошибка: цвета второй колонки совпадают." >&2
        exit 1
    fi
    
    # === БЛОК 4: ВОЗВРАТ РЕЗУЛЬТАТА ===
    # Мы просто печатаем (echo) все 8 чисел в одну строку.
    # Главный скрипт подхватит эту строку и разложит её по переменным.
    echo "$col1_bg $col1_fg $col2_bg $col2_fg $col1_bg_is_default $col1_fg_is_default $col2_bg_is_default $col2_fg_is_default"
}