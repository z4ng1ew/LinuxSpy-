#!/usr/bin/env bash

gather_system_facts() {
    
    # === БЛОК 1: ИМЯ ХОСТА ===
    local node_name
    # Пытаемся взять короткое имя (-s). Если ошибка (||) — берем полное.
    node_name=$(hostname -s 2>/dev/null || hostname)


    # === БЛОК 2: ВРЕМЯ И ЧАСОВОЙ ПОЯС ===
    local tz_name tz_offset
    # Проверяем, жив ли timedatectl (это системная служба времени).
    if command -v timedatectl &>/dev/null && timedatectl status &>/dev/null; then
        # --value: вернуть только значение (без названия параметра).
        tz_name=$(timedatectl show --value --property=Timezone 2>/dev/null)
        
        # Если переменная пустая (-z), ставим UTC.
        [[ -z "$tz_name" ]] && tz_name="UTC"
        
        # МАГИЯ СМЕЩЕНИЯ (OFFSET):
        # date +"%:::z" — это современный формат, выдает "+03" или "-05".
        # Если не сработало (||), включается "хирургия" через sed (для старых систем).
        tz_offset=$(date +"%:::z" 2>/dev/null || date +"%z" | sed 's/\([+-][0-9][0-9]\).*/\1/' | sed 's/0\([0-9]\)/\1/')
    else
        # Запасной вариант (Fallback), если службы времени нет.
        tz_name="UTC"
        tz_offset="0"
    fi


    # === БЛОК 3: ПОЛЬЗОВАТЕЛЬ И ОС ===
    local active_user
    active_user=$(whoami) # "Кто я?"

    local os_release
    # Ищем имя ОС тремя способами по очереди (от лучшего к худшему).
    if command -v hostnamectl &>/dev/null && hostnamectl status &>/dev/null; then
        # awk -F': ': Разделитель — двоеточие с пробелом. Берем 2-й столбец.
        os_release=$(hostnamectl | awk -F': ' '/Operating System/ {print $2; exit}')
    elif command -v lsb_release &>/dev/null; then
        # cut -f2: "Разрежь строку и дай мне 2-й кусок".
        os_release=$(lsb_release -d 2>/dev/null | cut -f2)
    else
        # uname -s: Просто ядро (Linux).
        os_release=$(uname -s 2>/dev/null || echo "Unknown")
    fi


    # === БЛОК 4: ФОРМАТИРОВАНИЕ ДАТЫ ===
    local current_moment
    # LC_TIME=C: Включаем "английский режим" для даты (чтобы было "Dec", а не "Дек").
    # sed 's/^0//': Если число начинается с 0 (например, 05 мая), удаляем этот ноль (^0).
    current_moment=$(LC_TIME=C date +"%d %b %Y %H:%M:%S" | sed 's/^0//')


    # === БЛОК 5: UPTIME (ВРЕМЯ РАБОТЫ) ===
    local uptime_human uptime_seconds
    if [[ -f /proc/uptime ]]; then
        # Читаем "сырые" секунды из файла ядра /proc/uptime.
        uptime_seconds=$(awk '{printf "%.0f", $1}' /proc/uptime)
        
        local days hours mins
        # МАТЕМАТИКА:
        # / 86400 — делим секунды на кол-во секунд в дне. (Целое число).
        # % 86400 — берем ОСТАТОК от деления (то, что не влезло в дни).
        days=$((uptime_seconds / 86400))
        hours=$(((uptime_seconds % 86400) / 3600))
        mins=$(((uptime_seconds % 3600) / 60))
        
        # СБОРКА СТРОКИ (Human Readable):
        uptime_human=""
        if [[ $days -gt 0 ]]; then
            # Проверка на множественное число: 1 day vs 2 days.
            [[ $days -eq 1 ]] && uptime_human="${days} day" || uptime_human="${days} days"
            uptime_human+=", "
        fi
        # То же самое для часов и минут.
        [[ $hours -eq 1 ]] && uptime_human+="${hours} hour" || uptime_human+="${hours} hours"
        uptime_human+=", "
        [[ $mins -eq 1 ]] && uptime_human+="${mins} minute" || uptime_human+="${mins} minutes"
    else
        uptime_seconds="N/A"
        uptime_human="N/A"
    fi


    # === БЛОК 6: СЕТЬ (IP И МАРШРУТЫ) ===
    local main_iface
    # Узнаем главную карту, пытаясь "постучаться" к Google DNS (8.8.8.8).
    # awk '{print $5}': Пятый столбец вывода ip route get содержит имя интерфейса.
    main_iface=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}' || echo "eth0")

    local machine_ip subnet_mask default_gateway
    # awk '/inet/': Ищем строку с IPv4 адресом.
    # cut -d'/' -f1: Отрезаем маску (всё, что после слеша).
    machine_ip=$(ip -4 addr show dev "$main_iface" 2>/dev/null | awk '/inet/ {print $2; exit}' | cut -d'/' -f1)
    [[ -z "$machine_ip" ]] && machine_ip="N/A"

    # === БЛОК 7: ВЫЧИСЛЕНИЕ МАСКИ ПОДЕТИ (СЛОЖНАЯ МАТЕМАТИКА) ===
    local cidr_prefix
    # Вытаскиваем число после слеша (например, 24 из 192.168.1.5/24).
    cidr_prefix=$(ip -4 addr show dev "$main_iface" 2>/dev/null | awk '/inet/ {print $2; exit}' | cut -d'/' -f2)
    
    if [[ -n "$cidr_prefix" ]]; then
        # ЗАПУСКАЕМ AWK КАК КАЛЬКУЛЯТОР (-v prefix=... передает переменную внутрь).
        subnet_mask=$(awk -v prefix="$cidr_prefix" 'BEGIN {
            # Защита от дурака: префикс должен быть от 0 до 32.
            if (prefix == "" || prefix < 0 || prefix > 32) {
                print "N/A";
                exit;
            }
            mask = 0;
            # 1. СТРОИМ БИТОВУЮ МАСКУ (Цепочка единиц)
            # Цикл бежит столько раз, каков префикс (например, 24 раза).
            # * 2 + 1 — это сдвиг влево и добавление единички в конец.
            # Мы рисуем в памяти число из 24 единиц подряд.
            for (i = 0; i < prefix; i++) mask = mask * 2 + 1;
            
            # 2. ДОБИВАЕМ НУЛЯМИ
            # Оставшиеся биты (до 32) заполняем нулями (просто умножаем на 2).
            for (i = prefix; i < 32; i++) mask = mask * 2;
            
            # 3. РАЗРЕЗАЕМ НА ОКТЕТЫ (X.X.X.X)
            # Делим огромное число на "вес" каждого байта (16 млн, 65 тыс, 256), чтобы получить части IP.
            # % 256 — отсекаем лишнее, оставляя число от 0 до 255.
            printf "%d.%d.%d.%d", int(mask/16777216)%256, int(mask/65536)%256, int(mask/256)%256, mask%256;
        }')
    else
        subnet_mask="N/A"
    fi

    # Шлюз по умолчанию (Gateway) — это адрес роутера.
    default_gateway=$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')
    [[ -z "$default_gateway" ]] && default_gateway="N/A"


    # === БЛОК 8: ОПЕРАТИВНАЯ ПАМЯТЬ (RAM) ===
    local ram_total_gb ram_used_gb ram_free_gb
    if command -v free &>/dev/null; then
        # < <(...) — ПОДСТАНОВКА ПРОЦЕССА.
        # Это позволяет переменным ram_... выжить после выхода из цикла read.
        # LC_ALL=C: Чтобы free писало "Mem:", а не "Память:".
        # free -b: Вывод в байтах для точности.
        read -r ram_total_gb ram_used_gb ram_free_gb < <(
            LC_ALL=C free -b | awk '/Mem:/ {
                # Делим байты на 1073741824 (это 1024*1024*1024), чтобы получить Гигабайты.
                # %.3f — оставляем 3 знака после запятой.
                printf "%.3f %.3f %.3f", $2/1073741824, $3/1073741824, $4/1073741824
            }'
        )
    else
        ram_total_gb="N/A" ram_used_gb="N/A" ram_free_gb="N/A"
    fi


    # === БЛОК 9: ЖЕСТКИЙ ДИСК (КОРЕНЬ /) ===
    local root_total_mb root_used_mb root_free_mb
    if command -v df &>/dev/null; then
        read -r root_total_mb root_used_mb root_free_mb < <(
            # df -B1 /: Смотрим только корень (/), размер в байтах.
            # awk 'NR==2': Берем ТОЛЬКО вторую строку (первая — это заголовки).
            df -B1 / 2>/dev/null | awk 'NR==2 {
                # Делим на 1048576 (это 1024*1024), чтобы получить Мегабайты.
                printf "%.2f %.2f %.2f", $2/1048576, $3/1048576, $4/1048576
            }'
        )
    else
        root_total_mb="N/A" root_used_mb="N/A" root_free_mb="N/A"
    fi


    # === БЛОК 10: ГЕНЕРАЦИЯ ОТЧЕТА ===
    # cat <<EOF — HEREDOC.
    # Мы выводим огромный кусок текста, подставляя туда значения наших переменных.
    cat <<EOF
HOSTNAME = $node_name
TIMEZONE = $tz_name UTC $tz_offset
USER = $active_user
OS = $os_release
DATE = $current_moment
UPTIME = $uptime_human
UPTIME_SEC = ${uptime_seconds} seconds
IP = $machine_ip
MASK = $subnet_mask
GATEWAY = $default_gateway
RAM_TOTAL = ${ram_total_gb} GB
RAM_USED = ${ram_used_gb} GB
RAM_FREE = ${ram_free_gb} GB
SPACE_ROOT = ${root_total_mb} MB
SPACE_ROOT_USED = ${root_used_mb} MB
SPACE_ROOT_FREE = ${root_free_mb} MB
EOF
}