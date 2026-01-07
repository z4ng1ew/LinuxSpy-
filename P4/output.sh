#!/usr/bin/env bash

print_color_scheme() {
    # Принимаем кучу аргументов (сами цвета и флаги "дефолтности")
    local col1_bg=$1
    # ... и так далее до $8 ...
    
    # === ВНУТРЕННЯЯ ФУНКЦИЯ print_line ===
    # Чтобы не писать 4 раза одно и то же echo, создадим маленькую функцию прямо тут.
    print_line() {
        local name=$1  # Название параметра (текст)
        local val=$2   # Значение (цифра)
        local is_def=$3 # Флаг (1 - дефолт, 0 - из конфига)
        
        # Получаем текстовое название цвета (например, "red")
        local color_name
        color_name=$(get_color_name "$val")
        
        if [[ $is_def -eq 1 ]]; then
            echo "$name = default ($color_name)"
        else
            echo "$name = $val ($color_name)"
        fi
    }

    # Вызываем нашу микро-функцию для каждого параметра
    print_line "Column 1 background" "$col1_bg" "$col1_bg_is_default"
    print_line "Column 1 font color" "$col1_fg" "$col1_fg_is_default"
    # ...
}