#!/usr/bin/env bash

gather_system_facts() {
    # set +e — "Расслабленный режим". Отключаем мгновенную смерть при ошибках.
    # Если какая-то команда сбора данных (например, ip) сбойнет, мы не хотим убивать весь отчет.
    set +e
    
    # === БЛОК 1: ПОДГОТОВКА ЦВЕТОВ ===
    local bg_name=$1  # Цифра цвета фона названий
    local fg_name=$2  # Цифра цвета шрифта названий
    local bg_value=$3 # ... фона значений
    local fg_value=$4 # ... шрифта значений
    
    # Переменные для хранения КОДОВ (например, "41", "32").
    local color_bg_name color_fg_name color_bg_value color_fg_value
    
    # ВЫЗОВ ФУНКЦИИ ИЗ colors.sh:
    # $(get_color "$bg_name" 1) — Мы говорим: "Дай мне код для цифры $bg_name, и это будет ФОН (1)".
    color_bg_name=$(get_color "$bg_name" 1)
    color_fg_name=$(get_color "$fg_name" 0) # 0 значит шрифт
    color_bg_value=$(get_color "$bg_value" 1)
    color_fg_value=$(get_color "$fg_value" 0)
    
    # === БЛОК 2: СБОРКА ANSI-СТРОКИ ===
    # Это самое важное место для раскраски!
    
    # \033[0m — Это команда "Сброс". Она выключает все цвета и возвращает стандартный терминал.
    local reset="\033[0m"
    
    # ФОРМУЛА ЦВЕТА: \033[ФОН;ШРИФТm
    # \033[ — ESCAPE-последовательность (начало команды терминалу).
    # ${color_bg_name} — подставляем код фона (напр. 41).
    # ; — разделитель.
    # ${color_fg_name} — подставляем код шрифта (напр. 37).
    # m — конец команды настройки цвета.
    local name_style="\033[${color_bg_name};${color_fg_name}m"
    local value_style="\033[${color_bg_value};${color_fg_value}m"

    # === БЛОК 3: СБОР ДАННЫХ (Кратко) ===
    # (Этот код мы разбирали ранее, он собирает Hostname, IP, RAM и т.д.)
    # ... (код сбора данных) ...

    # === БЛОК 4: ВЫВОД С ЦВЕТАМИ ===
    # echo -e: Включает обработку спецсимволов (тех самых \033).
    
    # ${name_style}HOSTNAME${reset}:
    # 1. Включаем стиль названий (например, красный фон).
    # 2. Пишем слово HOSTNAME.
    # 3. Делаем reset (сброс), чтобы знак "равно" был обычного цвета.
    
    # ${value_style}$node_name${reset}:
    # 1. Включаем стиль значений (например, зеленый фон).
    # 2. Выводим переменную $node_name.
    # 3. Снова сброс.
    
    echo -e "${name_style}HOSTNAME${reset} = ${value_style}$node_name${reset}"
    echo -e "${name_style}TIMEZONE${reset} = ${value_style}$tz_name UTC $tz_offset${reset}"
    echo -e "${name_style}USER${reset} = ${value_style}$active_user${reset}"
    # ... и так далее для всех строк ...
    
    # set -e: Возвращаем "Строгий режим" перед выходом из функции.
    set -e
}