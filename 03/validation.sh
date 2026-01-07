#!/usr/bin/env bash

validate_parameters() {
    if [[ $# -ne 4 ]]; then
        echo "Ошибка: скрипт должен быть запущен с 4 параметрами."
        echo "Использование: ./main.sh <цвет_фона_названий> <цвет_шрифта_названий> <цвет_фона_значений> <цвет_шрифта_значений>"
        echo "Цвета: 1-white, 2-red, 3-green, 4-blue, 5-purple, 6-black"
        exit 1
    fi
    
    local param1=$1
    local param2=$2
    local param3=$3
    local param4=$4
    
    for param in "$param1" "$param2" "$param3" "$param4"; do
        if ! [[ "$param" =~ ^[1-6]$ ]]; then
            echo "Ошибка: все параметры должны быть числами от 1 до 6."
            echo "Цвета: 1-white, 2-red, 3-green, 4-blue, 5-purple, 6-black"
            exit 1
        fi
    done
    
    if [[ $param1 -eq $param2 ]]; then
        echo "Ошибка: цвет фона и цвет шрифта для названий не должны совпадать."
        echo "Параметр 1 (фон названий) = $param1, Параметр 2 (шрифт названий) = $param2"
        echo "Пожалуйста, запустите скрипт повторно с другими параметрами."
        exit 1
    fi
    
    if [[ $param3 -eq $param4 ]]; then
        echo "Ошибка: цвет фона и цвет шрифта для значений не должны совпадать."
        echo "Параметр 3 (фон значений) = $param3, Параметр 4 (шрифт значений) = $param4"
        echo "Пожалуйста, запустите скрипт повторно с другими параметрами."
        exit 1
    fi
}