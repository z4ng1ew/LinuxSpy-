#!/usr/bin/env bash

gather_system_facts() {
    set +e # Временно отключаем строгий режим (чтобы ошибка ip не убила скрипт)
    
    # === БЛОК 1: ПРИЕМ АРГУМЕНТОВ ===
    # Сюда приходят 4 цифры цветов из main.sh
    local bg_name=$1
    local fg_name=$2
    local bg_value=$3
    local fg_value=$4
    
    # === БЛОК 2: ПОЛУЧЕНИЕ ANSI-КОДОВ ===
    # $(get_color "$bg_name" 1) — Вызываем функцию из colors.sh.
    # Она вернет, например, "46".
    local color_bg_name color_fg_name color_bg_value color_fg_value
    color_bg_name=$(get_color "$bg_name" 1)
    color_fg_name=$(get_color "$fg_name" 0)
    # ...
    
    # === БЛОК 3: СОЗДАНИЕ СТИЛЕЙ ===
    local reset="\033[0m" # Сброс всех цветов
    
    # Конструктор цвета: \033[ ФОН ; ШРИФТ m
    local name_style="\033[${color_bg_name};${color_fg_name}m"
    local value_style="\033[${color_bg_value};${color_fg_value}m"

    # ... (Далее идет стандартный блок сбора данных: hostname, time, ram) ...

    # === БЛОК 4: ВЫВОД НА ЭКРАН ===
    # echo -e: Включает интерпретацию escape-символов (\033).
    # ${name_style}HOSTNAME${reset}: Печатаем слово HOSTNAME в стиле 1, потом сбрасываем цвет.
    # = : Обычный знак равно.
    # ${value_style}$node_name${reset}: Печатаем значение переменной в стиле 2.
    echo -e "${name_style}HOSTNAME${reset} = ${value_style}$node_name${reset}"
    # ...
    
    set -e # Возвращаем строгий режим
}