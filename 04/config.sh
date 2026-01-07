#!/usr/bin/env bash

CONFIG_FILE="$(dirname "${BASH_SOURCE[0]}")/config.conf"

DEFAULT_COLUMN1_BG=6
DEFAULT_COLUMN1_FG=1
DEFAULT_COLUMN2_BG=2
DEFAULT_COLUMN2_FG=4

load_config() {
    local col1_bg=$DEFAULT_COLUMN1_BG
    local col1_fg=$DEFAULT_COLUMN1_FG
    local col2_bg=$DEFAULT_COLUMN2_BG
    local col2_fg=$DEFAULT_COLUMN2_FG
    
    local col1_bg_is_default=1
    local col1_fg_is_default=1
    local col2_bg_is_default=1
    local col2_fg_is_default=1
    
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS='=' read -r key value; do
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            
            key=$(echo "$key" | tr -d '[:space:]')
            value=$(echo "$value" | tr -d '[:space:]')
            
            if [[ "$value" =~ ^[1-6]$ ]]; then
                case "$key" in
                    column1_background) col1_bg=$value; col1_bg_is_default=0 ;;
                    column1_font_color) col1_fg=$value; col1_fg_is_default=0 ;;
                    column2_background) col2_bg=$value; col2_bg_is_default=0 ;;
                    column2_font_color) col2_fg=$value; col2_fg_is_default=0 ;;
                esac
            fi
        done < "$CONFIG_FILE"
    fi

    if [[ $col1_bg -eq $col1_fg ]]; then
        echo "Ошибка: цвет фона и цвет шрифта для названий не должны совпадать." >&2
        echo "Column 1 background = $col1_bg, Column 1 font color = $col1_fg" >&2
        echo "Пожалуйста, измените конфигурационный файл." >&2
        exit 1
    fi
    
    if [[ $col2_bg -eq $col2_fg ]]; then
        echo "Ошибка: цвет фона и цвет шрифта для значений не должны совпадать." >&2
        echo "Column 2 background = $col2_bg, Column 2 font color = $col2_fg" >&2
        echo "Пожалуйста, измените конфигурационный файл." >&2
        exit 1
    fi
    
    echo "$col1_bg $col1_fg $col2_bg $col2_fg $col1_bg_is_default $col1_fg_is_default $col2_bg_is_default $col2_fg_is_default"
}