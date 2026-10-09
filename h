#!/bin/bash
# =====================================================================
#  h - запуск задач и лабораторных работ ПАБД (база SALES), варианты 20 и 22
#  Работает в Git Bash под Windows из корня проекта: ./h <команда> [параметры]
#  PostgreSQL - через psql, MS SQL Server (ЛР6, ЛР7) и сборка на C (ЛР5) - через .bat
# =====================================================================
cd "$(dirname "$0")" || exit 1

export PGHOST=${PGHOST:-localhost}
export PGPORT=${PGPORT:-5432}
export PGUSER=${PGUSER:-postgres}
export PGDATABASE=${PGDATABASE:-sales}
export PGCLIENTENCODING=UTF8
export MSYS_NO_PATHCONV=1

# psql-сценарий с параметрами arg1..arg3 (как s.bat): параметры передаются через stdin
# командами \set, т.к. psql под Windows получает argv в CP1251 и кириллица в -v ломается.
# Вывод проходит через helper/fixenc.pl (служебные сообщения psql приходят в CP1251).
# RUN_STOP=1 run ... - с ON_ERROR_STOP: при ошибке psql останавливается, run возвращает его код
run() {
    local file="$1"; shift
    if [ ! -f "$file" ]; then
        echo "ОШИБКА: Файл $file не найден"
        exit 1
    fi
    echo ">>> Файл: $file"
    {
        [ -n "$RUN_STOP" ] && printf '\\set ON_ERROR_STOP on\n'
        local i=1
        for a in "$1" "$2" "$3" "$4" "$5"; do
            printf "\\\\set arg%d '%s'\n" "$i" "${a//\'/\'\'}"
            i=$((i + 1))
        done
        printf "\\\\i '%s'\n" "$file"
    } | psql -q -X -P pager=off -P "null=<null>" -f - 2>&1 | perl helper/fixenc.pl
    return "${PIPESTATUS[1]}"
}

# psql-сценарий в системной базе postgres (как s1.bat)
run_pg() {
    echo ">>> Файл: $1 (база postgres)"
    PGDATABASE=postgres psql -q -X -P pager=off -f "$1" 2>&1 | perl helper/fixenc.pl
}

# командный файл Windows: путь в формате Windows, параметры как есть
bat() {
    echo ">>> Файл: $1"
    local file; file=$(cygpath -w "$1"); shift
    cmd.exe /c "$file" "$@"
}

# адрес сервера [пользователь@]хост[:порт] -> переменные ${1}HOST, ${1}PORT, ${1}USER
set_addr() {
    local addr=$2
    if [[ "$addr" == *@* ]]; then export "${1}USER=${addr%%@*}"; addr=${addr#*@}; fi
    if [[ "$addr" == *:* ]]; then export "${1}PORT=${addr##*:}"; addr=${addr%:*}; fi
    export "${1}HOST=$addr"
}

need_variant() {
    if [ "$1" != "20" ] && [ "$1" != "22" ]; then
        echo "ОШИБКА: Укажите вариант 20 или 22"
        exit 1
    fi
}

# команды-аналоги TAXI-db: таблица helper/menu.txt (код|файл|параметры|обязательных|описание|пример|типы)
show_menu() {
    local code file params req desc ex cmd pad
    local LC_ALL=C.UTF-8     # длина строки ${#cmd} - в символах, а не в байтах
    while IFS='|' read -r code file params req desc ex types; do
        case "$code" in
            ''|'#'*) continue ;;
            '== '*) echo ""; echo "================== БАЗА SALES: ${code#== } =================="; continue ;;
        esac
        cmd="./h $code${params:+ $params}"
        pad=$((36 - ${#cmd})); [ $pad -lt 0 ] && pad=0
        printf '  %s%*s - %s  [%s]\n' "$cmd" $pad '' "$desc" "$file"
        [ -n "$ex" ] && printf '  %36s   пример: ./h %s %s\n' '' "$code" "$ex"
    done < helper/menu.txt
}

need_task() {
    if [ "$1" != "1" ] && [ "$1" != "2" ]; then
        echo "ОШИБКА: Укажите номер задания 1 или 2"
        exit 1
    fi
}

# ---------------- проверка параметров (helper/args.txt, helper/menu.txt) ----------------
# param_error тип значение - текст ошибки формата (пусто - значение подходит); типы - helper/args.txt
param_error() {
    local v=$2 re_date='^[0-9]{2}\.[0-9]{2}\.[0-9]{4}$' re_year='^(19|20)[0-9]{2}$'
    case "$1" in
        variant) [[ $v == 20 || $v == 22 ]] || echo "нужен вариант 20 или 22" ;;
        int)     [[ $v =~ ^[1-9][0-9]*$ ]] || echo "нужно целое число больше 0" ;;
        n)       [[ $v =~ ^[0-9]+$ ]] || echo "нужно целое число (0 и больше)" ;;
        *#)      [[ $v =~ ^[0-9]+$ ]] || echo "нужен код - целое число" ;;
        num)     [[ $v =~ ^[0-9]+(\.[0-9]+)?$ ]] || echo "нужно число, дробная часть через точку (например 8.5)" ;;
        year)    [[ $v =~ $re_year ]] || echo "нужен год ГГГГ (например 2019)" ;;
        date)    [[ $v =~ $re_date ]] &&
                 [ "$(date -d "${v:6:4}-${v:3:2}-${v:0:2}" +%d.%m.%Y 2>/dev/null)" = "$v" ] ||
                 echo "нужна дата ДД.ММ.ГГГГ (например 01.07.2019)" ;;
        dow)     case $v in пн|вт|ср|чт|пт|сб|вс) ;; *) echo "нужен день недели: пн вт ср чт пт сб вс" ;; esac ;;
        season)  case $v in зима|весна|лето|осень) ;; *) echo "нужно время года: зима весна лето осень" ;; esac ;;
        idx)     [[ $v == btree || $v == hash ]] || echo "нужен тип индекса btree или hash" ;;
        one)     [ "$v" = 1 ] || echo "допустимо только 1 (с условием WHERE)" ;;
        size)    [[ $v =~ ^[1-9][0-9]*[kKmMgG]?$ ]] || echo "нужен размер тома: число с k, m или g (например 8k)" ;;
        cs)      [[ $v == *.cs ]] && { [ -f "lab8/v20/$v" ] || [ -f "$v" ]; } ||
                 echo "нужен существующий файл .cs (в lab8/v20)" ;;
    esac
}

# check_params команда обязательных "типы" "использование" "пример" параметры...
# Число и формат параметров, порядок дат/годов; значения из базы - helper/check_db.sql
# (PostgreSQL) или lab6/check_db.sql (MS SQL Server, команды lr6, lr7, lr8).
# При ошибке - сообщение, использование и выход с кодом 1
check_params() {
    local cmd=$1 req=$2 usage=$4 ex=$5 err="" v i=0 given=0 prev="" pv=""
    local -a t=($3) db=()
    shift 5
    for v in "$@"; do [ -n "$v" ] && given=$((given + 1)); done
    if [ $# -gt ${#t[@]} ]; then
        err="лишние параметры: ${*:${#t[@]}+1}"
    elif [ "$given" -lt "$req" ]; then
        err="не хватает параметров (обязательных: $req)"
    fi
    for v in "$@"; do
        [ -n "$err" ] && break
        if [ -n "$v" ]; then
            err=$(param_error "${t[$i]}" "$v")
            if [ -n "$err" ]; then err="параметр $((i + 1)) «$v»: $err"; break; fi
            # две даты или два года подряд: первый не позже второго
            if [ "${t[$i]}" = "$prev" ] && [ -n "$pv" ] &&
               { [[ $prev == date && "${pv:6:4}${pv:3:2}${pv:0:2}" > "${v:6:4}${v:3:2}${v:0:2}" ]] ||
                 [[ $prev == year && $pv > $v ]]; }; then
                err="начало периода $pv позже конца $v"; break
            fi
            case "${t[$i]}" in
                cat|cat~|prov|prov#|goods|goods#|client#|surname|emp|emp#|district#) db+=("${t[$i]}" "$v") ;;
            esac
        fi
        prev=${t[$i]}; pv=$v; i=$((i + 1))
    done
    if [ -n "$err" ]; then
        echo "ОШИБКА: $err"
        echo "Использование: $cmd${usage:+ $usage}"
        [ -n "$ex" ] && echo "Пример:        $cmd $ex"
        exit 1
    fi
    [ ${#db[@]} -eq 0 ] && return
    # ЛР6-ЛР8 работают с MS SQL Server - значения проверяются там (данные могут отличаться)
    if [[ $cmd =~ \ lr[678]\  ]]; then
        echo ">>> Файл: lab6/check_db.sql (MS SQL Server)"
        cmd.exe /c "$(cygpath -w lab6/s.bat)" "$(cygpath -w lab6/check_db.sql)" "${db[@]}"
    else
        RUN_STOP=1 run helper/check_db.sql "${db[@]}"
    fi
    case $? in
        0) ;;
        3) exit 1 ;;
        *) echo "ВНИМАНИЕ: значения параметров не проверены по базе (нет подключения)" ;;
    esac
}

# check_cmd префикс слова команды и параметры: строка helper/args.txt по первым 3, 2 или 1
# словам (префикс - для подсказки: "./h" или "./h srv"); команда без строки не проверяется
check_cmd() {
    local pre=$1 n key line req types usage
    shift
    for n in 3 2 1; do
        [ $# -lt $n ] && continue
        key="${*:1:$n}"
        line=$(awk -F'|' -v k="$key" '$1 == k { print; exit }' helper/args.txt)
        [ -z "$line" ] && continue
        IFS='|' read -r key req types usage <<< "$line"
        check_params "$pre $key" "$req" "$types" "$usage" "" "${@:n+1}"
        return
    done
}

# справка по блокам: help_<блок> выводит один раздел (./h short <блок>), ./h - все разделы
help_lr1() {
    echo "================== ЛР1: БАЗА И ЗАДАНИЯ =================="
    echo "  ./h db              - создать БД sales, таблицы и загрузить данные  [DATA/create_DB, DATA/create_tables, DATA/load_data]"
    echo "  ./h counts          - количество строк в таблицах  [helper/counts.sql]"
    echo "  ./h v20 1 [дата1 дата2 [категория]]  - в.20: объём поставок по категории и кварталу  [tasks/v20_task1.sql]"
    echo "                                         пример: ./h v20 1 01.01.2021 31.12.2022 мебель"
    echo "  ./h v20 2 [год1 год2 [день недели]]  - в.20: продажи (шт) по дню недели и району  [tasks/v20_task2.sql]"
    echo "                                         пример: ./h v20 2 2019 2023 пн"
    echo "  ./h v22 1 [дата1 дата2 [поставщик]]  - в.22: выручка по поставщику и декаде  [tasks/v22_task1.sql]"
    echo "                                         пример: ./h v22 1 01.07.2019 30.06.2023 \"ООО Турман\""
    echo "  ./h v22 2 [год1 год2 [время года]]   - в.22: затраты клиентов по сезону и полу  [tasks/v22_task2.sql]"
    echo "                                         пример: ./h v22 2 2018 2022 зима"
    echo "  ./h all             - все 4 задания с параметрами по умолчанию  [tasks/*.sql]"
    echo "  ./h lr1 lan         - настроить pg_hba.conf и брандмауэр для сети (от администратора)  [lan_server/setup_lan.ps1]"
    echo "  ./h lr1 client [адрес] сценарий [a1 a2 a3] - сценарий через s_lan.bat на сервере в сети (по умолч. postgres@192.168.0.102:5432)  [lan_server/s_lan.bat]"
    echo "                                         пример: ./h lr1 client 192.168.0.102 tasks/v20_task1.sql 01.01.2021 31.12.2022 мебель"
    echo "                                                 ./h lr1 client postgres@192.168.0.102:5432 tasks/v22_task1.sql 01.07.2019 30.06.2023 \"ООО Турман\""
    echo "  ./h srv [адрес] [check]   - сервер в сети PMII (по умолч. stud@192.168.1.50:5432): подключение и таблицы  [lan_server/check_server.sql]"
    echo "                                         пример: ./h srv 192.168.1.50 check"
    echo "  ./h srv [адрес] v20|v22 1|2 [параметры] - задание варианта на сервере в сети  [tasks/vNN_taskN.sql]"
    echo "                                         пример: ./h srv 192.168.1.50 v20 1 01.01.2021 31.12.2022 мебель"
    echo "                                                 ./h srv stud@192.168.1.50:5432 v22 2 2018 2022 зима"
    echo "  ./h srv [адрес] all       - проверка и все 4 задания на сервере; ./h srv [адрес] psql - консоль"
    echo "  (адрес - [пользователь@]хост[:порт]; пароль - SRV_PASS или pgpass.conf)"
}

help_lr2() {
    echo "================== ЛР2: ОБЪЁМНАЯ БД, ИНДЕКСЫ, EXPLAIN, ЗАЩИТА ЛР2 =================="
    echo "  ./h lr2 gen [N]           - ПРОДАЖА: N псевдослучайных записей (по умолч. 2 000 000)  [big_db_indexes/add_data.sql]"
    echo "                                         пример: ./h lr2 gen 2000000"
    echo "  ./h lr2 restore           - вернуть 1000 записей ПРОДАЖА из ЛР1  [big_db_indexes/restore_lr1.sql]"
    echo "  ./h lr2 tbs [каталог]     - вынести ПРОДАЖА в табличное пространство (D:/PG_TBS)  [big_db_indexes/tablespace.sql]"
    echo "                                         пример: ./h lr2 tbs D:/PG_TBS"
    echo "  ./h lr2 time 20|22 [замеров]   - время запроса (*) по CURRENT_TIME (по умолч. 5 замеров)  [big_db_indexes/time_current.sql, запрос big_db_indexes/vNN_query.sql]"
    echo "                                         пример: ./h lr2 time 20 5      ./h lr2 time 22 10"
    echo "  ./h lr2 timing 20|22 [замеров] - время запроса (*) по \\timing on (по умолч. 5 замеров)  [big_db_indexes/time_timing.sql, запрос big_db_indexes/vNN_query.sql]"
    echo "                                         пример: ./h lr2 timing 20 5    ./h lr2 timing 22 10"
    echo "  ./h lr2 idx 20|22         - индексы ПРОДАЖА и таблицы-справочника  [big_db_indexes/idx_names.sql]"
    echo "                                         пример: ./h lr2 idx 20      ./h lr2 idx 22"
    echo "  ./h lr2 idx1 20|22 [btree|hash] - создать индекс ПРОДАЖА по полю-ссылке (по умолч. btree)  [big_db_indexes/idx_1.sql]"
    echo "                                         пример: ./h lr2 idx1 20 btree      ./h lr2 idx1 22 hash"
    echo "  ./h lr2 idx0 20|22        - удалить индекс ПРОДАЖА по полю-ссылке  [big_db_indexes/idx_0.sql]"
    echo "                                         пример: ./h lr2 idx0 20      ./h lr2 idx0 22"
    echo "  ./h lr2 pk1 20|22         - справочник с PRIMARY KEY  [big_db_indexes/create_ref0.sql]"
    echo "                                         пример: ./h lr2 pk1 20      ./h lr2 pk1 22"
    echo "  ./h lr2 pk0 20|22         - справочник без PRIMARY KEY  [big_db_indexes/create_ref1.sql]"
    echo "                                         пример: ./h lr2 pk0 20      ./h lr2 pk0 22"
    echo "  ./h lr2 copy 20|22        - перезагрузить справочник из DATA/SOURCE  [big_db_indexes/copy_ref.sql]"
    echo "                                         пример: ./h lr2 copy 20      ./h lr2 copy 22"
    echo "  ./h lr2 explain 20|22 [1] - EXPLAIN / EXPLAIN ANALYZE (1 - с WHERE)  [big_db_indexes/explain.sql, запрос big_db_indexes/vNN_config.sql]"
    echo "                                         пример: ./h lr2 explain 20 1      ./h lr2 explain 22"
    echo "  ./h lr2 measure 20|22 [прогонов] - протокол замеров (по умолч. 3 прогона) -> results/lr2_vNN_results.txt  [big_db_indexes/measure.sql, запросы big_db_indexes/vNN_config.sql]"
    echo "                                         пример: ./h lr2 measure 20 3      ./h lr2 measure 22 5"
    echo "  ./h lr2 results 20|22     - показать протокол замеров  [results/lr2_vNN_results.txt]"
    echo "                                         пример: ./h lr2 results 20      ./h lr2 results 22"
    echo "  (запрос (*) и настройки варианта: big_db_indexes/vNN_query.sql, big_db_indexes/vNN_config.sql, big_db_indexes/config.sql)"
    echo "  --- защита ЛР2: индексы и время запроса варианта (big_db_indexes/def_*.sql) ---"
    echo "  ./h lr2 def 20 [all] [\"поставщик1\" \"поставщик2\"] - в.20: задания 1-3 подряд  [big_db_indexes/def_z_all.sql, запрос big_db_indexes/def_vNN_query.sql]"
    echo "                                         пример: ./h lr2 def 20 all \"ООО Турман\" \"ЧП Загорье\""
    echo "  ./h lr2 def 22 [all] [категория]  - в.22: задания 1-3 подряд  [big_db_indexes/def_z_all.sql, запрос big_db_indexes/def_vNN_query.sql]"
    echo "                                         пример: ./h lr2 def 22 all мебель"
    echo "  ./h lr2 def 20|22 1 [параметры] - 1) запрос варианта и результат  [big_db_indexes/def_z1_query.sql, запрос big_db_indexes/def_vNN_query.sql]"
    echo "                                         пример: ./h lr2 def 20 1 \"ООО Турман\" \"ЧП Загорье\"      ./h lr2 def 22 1 мебель"
    echo "  ./h lr2 def 20|22 2 [параметры] - 2) в.20 без индексов (показ: индексов 0, в плане не используются), в.22 с индексом ПРОДАЖА(товар) btree: 5 замеров в мс, минимум, EXPLAIN ANALYZE  [big_db_indexes/def_z2_noidx.sql, запрос big_db_indexes/def_vNN_query.sql]"
    echo "                                         пример: ./h lr2 def 20 2 \"ООО Турман\" \"ЧП Загорье\"      ./h lr2 def 22 2 мебель"
    echo "  ./h lr2 def 20|22 3 [параметры] - 3) индексы варианта, 5 замеров в мс, минимум, EXPLAIN ANALYZE, использование индексов в плане  [big_db_indexes/def_z3_idx.sql, запрос big_db_indexes/def_vNN_query.sql]"
    echo "                                         пример: ./h lr2 def 20 3 \"ООО Турман\" \"ЧП Загорье\"      ./h lr2 def 22 3 мебель"
    echo "  ./h lr2 def 20|22 idx         - индексы таблиц запроса варианта  [big_db_indexes/def_show_idx.sql]"
    echo "                                         пример: ./h lr2 def 20 idx      ./h lr2 def 22 idx"
    echo "  ./h lr2 def 20|22 idx_drop    - удалить индексы задания 3 своего варианта (def20_* / def22_*), остальные и PRIMARY KEY не трогаются  [big_db_indexes/def_idx_drop.sql]"
    echo "                                         пример: ./h lr2 def 20 idx_drop      ./h lr2 def 22 idx_drop"
    echo "  ./h lr2 def 20|22 idx_add     - создать индексы задания 3 своего варианта (def20_* / def22_*) без замеров  [big_db_indexes/def_idx_add.sql]"
    echo "                                         пример: ./h lr2 def 20 idx_add      ./h lr2 def 22 idx_add"
    echo "  ./h lr2 def restore           - удалить индексы защиты, вернуть PRIMARY KEY  [big_db_indexes/def_restore.sql]"
    echo "  (нужна объёмная ПРОДАЖА: ./h lr2 gen; в.20 по умолч. \"ООО Турман\" \"ЧП Загорье\", в.22 - мебель)"
    echo "  (параметры проверяются до запуска: поставщики - из ПОСТАВЩИК и разные, категория - из КАТЕГОРИЯ; при ошибке - список допустимых)"
}

help_lr3() {
    echo "================== ЛР3: ПОЛЬЗОВАТЕЛЬСКИЕ ТИПЫ =================="
    echo "  ./h lr3 cmplx             - пример преподавателя (complex)  [lab3/cmplx.sql]"
    echo "  ./h lr3 20                - в.20: трёхмерный вектор (vector3)  [lab3/v20_vector3.sql]"
    echo "  ./h lr3 22                - в.22: рациональное число (rational)  [lab3/v22_rational.sql]"
}

help_lr4() {
    echo "================== ЛР4: РЕЗЕРВНОЕ КОПИРОВАНИЕ =================="
    echo "  ./h lr4 all [20|22 [каталог]] - пп. 1-10 целиком -> results/lr4_vNN_protocol.txt  [lab4/run_all.bat]"
    echo "                                         пример: ./h lr4 all 20      ./h lr4 all 22 D:/LR4_WORK"
    echo "  ./h lr4 base [база]       - создать базу (по умолч. base) из данных ЛР1  [lab4/create_base.bat]"
    echo "                                         пример: ./h lr4 base base"
    echo "  ./h lr4 tasks N [база] [20|22] - контрольные задачи варианта -> taskN-01..03  [lab4/tasks.bat]"
    echo "                                         пример: ./h lr4 tasks 0 base 20      ./h lr4 tasks 0 base 22"
    echo "  ./h lr4 dump1|dump2 [база] - pg_dump в файл / rar  [lab4/dump-1.bat, dump-2.bat]"
    echo "                                         пример: ./h lr4 dump1 base      ./h lr4 dump2 base"
    echo "  ./h lr4 dump3 [том [база]] - pg_dump в многотомный rar (размер тома, по умолч. 8k)  [lab4/dump-3.bat]"
    echo "                                         пример: ./h lr4 dump3 10k base"
    echo "  (каталог копий по умолч. lab4/work; база по умолч. base, настройки - lab4/config.bat)"
}

help_lr5() {
    echo "================== ЛР5: ФУНКЦИИ НА C =================="
    echo "  ./h lr5 build 20|22 [каталог] - компиляция и сборка vNN.dll в каталог (по умолч. D:\\PG_DLL)  [lab5/build.bat]"
    echo "                                         пример: ./h lr5 build 20 D:/PG_DLL      ./h lr5 build 22 D:/PG_DLL"
    echo "  ./h lr5 20|22 [каталог]   - регистрация функций из каталога (по умолч. D:/PG_DLL) и демонстрация на таблице T  [lab5/vNN_test.sql]"
    echo "                                         пример: ./h lr5 20 D:/PG_DLL      ./h lr5 22 D:/PG_DLL"
}

help_lr6() {
    echo "================== ЛР6: КОПИРОВАНИЕ В MS SQL SERVER =================="
    echo "  ./h lr6 setup             - проверка сервера (база NEW1, таблица temp1)  [lab6/s_TCP.bat + lab6/SETUP/*]"
    echo "  ./h lr6 sel2              - собрать фильтр sel2.exe  [lab6/COPY/make_sel2.bat]"
    echo "  ./h lr6 createdb          - создать базу SALES в MS SQL Server  [lab6/COPY/create_DB]"
    echo "  ./h lr6 copy              - скопировать все таблицы sales из PostgreSQL  [lab6/COPY/copy_to_MS_SQL.bat]"
    echo "  ./h lr6 disp              - проверить скопированные таблицы  [lab6/COPY/disp.bat]"
    echo "  ./h lr6 v20|v22 1|2 [параметры] - задания варианта в MS SQL Server (параметры - как ./h v20|v22)  [lab6/tasks/vNN_taskN.sql]"
    echo "                                         пример: ./h lr6 v20 1 21.08.2020 20.08.2023 мебель      ./h lr6 v20 2 2019 2023 пн"
    echo "                                                 ./h lr6 v22 1 01.07.2019 30.06.2023 \"ООО Турман\"      ./h lr6 v22 2 2018 2022 зима"
    echo "  ./h lr6 console           - консоль sqlcmd  [lab6/s0.bat]"
}

help_lr7() {
    echo "================== ЛР7: ПРЕДСТАВЛЕНИЯ И ФУНКЦИИ MS SQL SERVER =================="
    echo "  ./h lr7 create            - создать представления и функции  [lab7/create_objects.sql]"
    echo "  ./h lr7 1 [D1 D2 P M [N]] - премия сотрудников (N - имя сотрудника)  [lab7/calculate1.sql]"
    echo "                                         пример: ./h lr7 1 01.01.2021 30.06.2021 8.5 10.5 Андрей"
    echo "  ./h lr7 2 [D1 D2 alpha [G]] - затраты на хранение (G - товар)  [lab7/calculate2.sql]"
    echo "                                         пример: ./h lr7 2 01.01.2021 30.06.2021 0.5 плащ"
}

help_lr8() {
    echo "================== ЛР8: ПРОГРАММЫ С ДАННЫМИ MS SQL SERVER =================="
    echo "  ./h lr8 build [файл.cs]   - компиляция программы C# варианта 20 (по умолч. Lab08.cs)  [lab8/v20/cs.bat]"
    echo "                                         пример: ./h lr8 build Lab08.cs"
    echo "  ./h lr8 20 [D1 D2 [категория]] - в.20 (C#): продажи (шт) по категории и кварталу  [lab8/v20/run.bat]"
    echo "                                         пример: ./h lr8 20 01.07.2019 30.06.2023 мебель"
    echo "  ./h lr8 22 [D1 D2 [поставщик]] - в.22 (Python): затраты клиентов по поставщику и декаде  [lab8/v22/run.bat]"
    echo "                                         пример: ./h lr8 22 01.10.2021 31.01.2024 \"ООО Турман\""
}

help_taxi() { show_menu; }

help_sql() {
    echo "================== ЗАПУСК SQL-ФАЙЛОВ =================="
    echo "  ./h файл.sql [a1 .. a5]   - выполнить любой psql-сценарий с параметрами arg1..arg5"
    echo "  ./h psql                  - консоль psql (база sales)"
    echo "  ./h reports [N ...]       - пересобрать отчёты .docx  [reports/make_reports.py]"
}

# ./h short - список блоков справки и команды для вывода каждого из них
show_short() {
    echo "============================================="
    echo "  ПАБД: КРАТКАЯ СПРАВКА ПО БЛОКАМ (ВАРИАНТЫ 20 И 22)"
    echo "============================================="
    echo "  Вывести подсказку только по одному блоку (лабораторной):"
    echo "  ./h short lr1       - ЛР1: база, задания вариантов, сервер в сети (db, counts, v20, v22, all, lr1, srv)"
    echo "  ./h short lr2       - ЛР2: объёмная БД, индексы, EXPLAIN и защита ЛР2 (lr2 ..., lr2 def ...)"
    echo "  ./h short lr3       - ЛР3: пользовательские типы (lr3 ...)"
    echo "  ./h short lr4       - ЛР4: резервное копирование (lr4 ...)"
    echo "  ./h short lr5       - ЛР5: функции на C (lr5 ...)"
    echo "  ./h short lr6       - ЛР6: копирование в MS SQL Server (lr6 ...)"
    echo "  ./h short lr7       - ЛР7: представления и функции MS SQL Server (lr7 ...)"
    echo "  ./h short lr8       - ЛР8: программы с данными MS SQL Server (lr8 ...)"
    echo "  ./h short taxi      - база SALES: аналоги команд TAXI-db (01 ... 204)  [helper/menu.txt]"
    echo "  ./h short sql       - запуск SQL-файлов, консоль psql, отчёты (файл.sql, psql, reports)"
    echo ""
    echo "  пример: ./h short lr2      ./h short 2   (номер лабораторной 1-8 = lr1-lr8)"
    echo "  ./h                 - вся справка сразу (без примеров запуска)"
    echo "  ./h example         - вся справка сразу с примерами запуска"
}

if [ "$1" = "short" ]; then
    [[ "$2" =~ ^[1-8]$ ]] && set -- "$1" "lr$2"
    if [ -z "$2" ]; then
        show_short
    elif declare -F "help_$2" >/dev/null; then
        "help_$2"
    else
        echo "ОШИБКА: Неизвестный блок справки $2 (./h short - список блоков)"
        exit 1
    fi
    exit 0
fi

# ./h - вся справка без строк "пример: ...", ./h example - с примерами
full_help() {
    echo "============================================="
    echo "  ПАБД: БАЗА ДАННЫХ SALES, ВАРИАНТЫ 20 И 22"
    echo "============================================="
    echo "  В [] - файл, который выполняет команда; при запуске он выводится строкой \">>> Файл: ...\"."
    echo "  Обработчик каждой команды - сценарий h (case, ветвь с именем команды)."
    echo "  Справка по одному блоку (лабораторной): ./h short - список блоков, ./h short lr2 - только ЛР2."
    echo "  Параметры проверяются до запуска: число, формат (даты, годы, числа, 20|22), значения из базы"
    echo "  (категория, поставщик, коды); при ошибке команда не выполняется [helper/args.txt, helper/menu.txt]."
    if [ "$1" = "example" ]; then
        echo "  Справка с примерами запуска; без примеров: ./h"
    else
        echo "  Справка без примеров запуска; с примерами: ./h example, по блоку: ./h short <блок>"
    fi
    echo ""
    help_lr1
    echo ""
    help_lr2
    echo ""
    help_lr3
    echo ""
    help_lr4
    echo ""
    help_lr5
    echo ""
    help_lr6
    echo ""
    help_lr7
    echo ""
    help_lr8
    help_taxi
    echo ""
    help_sql
}

if [ -z "$1" ] || [ "$1" = "example" ]; then
    if [ $# -gt 1 ]; then
        echo "ОШИБКА: лишние параметры: ${*:2}"
        echo "  ./h  или  ./h example"
        exit 1
    fi
    if [ "$1" = "example" ]; then full_help example; exit 0; fi
    full_help | grep -v -E '^ *пример:|^ {40,}\./h '   # пример и его строки-продолжения
    exit 1
fi

if [[ "$1" == *.sql ]]; then
    f="$1"; shift
    run "$f" "$@"
    exit 0
fi

# команды-аналоги TAXI-db (./h 01 ... ./h 204): файл и параметры - из helper/menu.txt
if [[ "$1" =~ ^[0-9]+$ ]] && line=$(grep -m1 "^$1|" helper/menu.txt); then
    IFS='|' read -r code file params req desc ex types <<< "$line"
    shift
    check_params "./h $code" "$req" "$types" "${params:+$params   }($desc)" "$ex" "$@"
    echo ">>> ./h $code - $desc"
    run "$file" "$@"
    exit 0
fi

# защита ЛР2: ./h lr2 def 20|22 [шаг] [параметры] и ./h lr2 def restore (big_db_indexes/def_*.sql)
# аргументы функции: вариант, шаг, параметры запроса
lr2_def() {
    if [ "$1" = "restore" ]; then
        if [ $# -gt 1 ]; then echo "ОШИБКА: у ./h lr2 def restore нет параметров"; exit 1; fi
        run big_db_indexes/def_restore.sql; exit 0
    fi
    need_variant "$1"
    local step=${2:-all} f max
    # параметров запроса: в.20 - не больше двух поставщиков, в.22 - одна категория
    max=$([ "$1" = "20" ] && echo 4 || echo 3)
    case "$step" in idx|idx_drop|idx_add) max=2 ;; esac
    if [ $# -gt $max ]; then
        echo "ОШИБКА: лишние параметры: ${*:$((max + 1))}"
        echo "  ./h lr2 def 20 [all|1|2|3] [\"поставщик1\" \"поставщик2\"]   ./h lr2 def 22 [all|1|2|3] [категория]"
        echo "  ./h lr2 def 20|22 idx|idx_drop|idx_add   ./h lr2 def restore"
        exit 1
    fi
    case "$step" in
        all) f=big_db_indexes/def_z_all.sql ;;
        1)   f=big_db_indexes/def_z1_query.sql ;;
        2)   f=big_db_indexes/def_z2_noidx.sql ;;
        3)   f=big_db_indexes/def_z3_idx.sql ;;
        idx)      run big_db_indexes/def_show_idx.sql "$1"; exit 0 ;;
        idx_drop) run big_db_indexes/def_idx_drop.sql "$1"; exit 0 ;;
        idx_add)  run big_db_indexes/def_idx_add.sql "$1"; exit 0 ;;
        *)   echo "ОШИБКА: ./h lr2 def 20|22 [all|1|2|3|idx|idx_drop|idx_add] [параметры]  или  ./h lr2 def restore"; exit 1 ;;
    esac
    # поставщики (в.20) или категория (в.22) должны быть в базе - иначе задание не запускается
    RUN_STOP=1 run big_db_indexes/def_check_args.sql "$1" "$3" "$4" || exit 1
    run "$f" "$1" "$3" "$4"
}

# число и формат параметров команды - по helper/args.txt
check_cmd ./h "$@"

case "$1" in
    # ------------------------------ ЛР1 ------------------------------
    db)
        run_pg DATA/create_DB
        run DATA/create_tables >/dev/null
        run DATA/load_data
        ;;
    counts) run helper/counts.sql ;;
    v20|v22)
        need_task "$2"
        run "tasks/$1_task$2.sql" "$3" "$4" "$5"
        ;;
    all)
        for t in v20_task1 v20_task2 v22_task1 v22_task2; do
            run "tasks/$t.sql"
        done
        ;;

    lr1)
        case "$2" in
            lan)    powershell -ExecutionPolicy Bypass -File lan_server/setup_lan.ps1 ;;
            client)
                # необязательный адрес сервера перед сценарием: [пользователь@]хост[:порт]
                if [ -n "$4" ] && [ ! -f "$3" ] && [ -f "$4" ]; then
                    set_addr LAN_ "$3"
                    set -- "$1" "$2" "${@:4}"
                fi
                if [ -z "$3" ]; then echo "Использование: ./h lr1 client [пользователь@]хост[:порт] сценарий [a1 a2 a3]"; exit 1; fi
                if [ ! -f "$3" ]; then echo "ОШИБКА: сценарий $3 не найден"; exit 1; fi
                if [ -n "$7" ]; then echo "ОШИБКА: лишние параметры: ${*:7} (у сценария не больше трёх)"; exit 1; fi
                bat lan_server/s_lan.bat "$(cygpath -w "$3")" "$4" "$5" "$6"
                ;;
            *) echo "ОШИБКА: ./h lr1 lan|client"; exit 1 ;;
        esac
        ;;

    # сервер преподавателя в сети PMII: те же сценарии ЛР1, подключение по IP
    srv)
        export PGHOST=${SRV_HOST:-192.168.1.50}
        export PGPORT=${SRV_PORT:-5432}
        export PGUSER=${SRV_USER:-stud}
        export PGPASSWORD=${SRV_PASS:-12345}
        export PGDATABASE=sales
        export PGCONNECT_TIMEOUT=10
        # необязательный адрес сервера: [пользователь@]хост[:порт] (содержит . @ или :)
        if [[ "$2" == *[.@:]* ]]; then
            set_addr PG "$2"
            set -- "$1" "${@:3}"
        fi
        echo "Сервер: $PGHOST:$PGPORT, база $PGDATABASE, пользователь $PGUSER"
        check_cmd "./h srv" "${@:2}"
        case "$2" in
            ""|check) run lan_server/check_server.sql ;;
            v20|v22)
                need_task "$3"
                run "tasks/$2_task$3.sql" "$4" "$5" "$6"
                ;;
            all)
                run lan_server/check_server.sql
                for t in v20_task1 v20_task2 v22_task1 v22_task2; do
                    run "tasks/$t.sql"
                done
                ;;
            psql) psql ;;
            *) echo "ОШИБКА: ./h srv [check|all|psql|v20 N|v22 N [параметры]]"; exit 1 ;;
        esac
        ;;

    # ------------------------------ ЛР2 ------------------------------
    lr2)
        case "$2" in
            gen)      run big_db_indexes/add_data.sql "$3" ;;
            restore)  run big_db_indexes/restore_lr1.sql ;;
            tbs)      run big_db_indexes/tablespace.sql "$3" ;;
            time)     need_variant "$3"; run big_db_indexes/time_current.sql "$3" "$4" ;;
            timing)   need_variant "$3"; run big_db_indexes/time_timing.sql "$3" "$4" ;;
            idx)      need_variant "$3"; run big_db_indexes/idx_names.sql "$3" ;;
            idx1)     need_variant "$3"; run big_db_indexes/idx_1.sql "$3" "$4" ;;
            idx0)     need_variant "$3"; run big_db_indexes/idx_0.sql "$3" ;;
            pk1)      need_variant "$3"; run big_db_indexes/create_ref0.sql "$3" ;;
            pk0)      need_variant "$3"; run big_db_indexes/create_ref1.sql "$3" ;;
            copy)     need_variant "$3"; run big_db_indexes/copy_ref.sql "$3" ;;
            explain)  need_variant "$3"; run big_db_indexes/explain.sql "$3" "$4" ;;
            measure)  need_variant "$3"; run big_db_indexes/measure.sql "$3" "$4"
                      cat "results/lr2_v$3_results.txt" ;;
            results)  need_variant "$3"; cat "results/lr2_v$3_results.txt" ;;
            def)      shift 2; lr2_def "$@" ;;
            *) echo "ОШИБКА: ./h lr2 gen|restore|tbs|time|timing|idx|idx1|idx0|pk1|pk0|copy|explain|measure|results|def"; exit 1 ;;
        esac
        ;;

    # ------------------------------ ЛР3 ------------------------------
    lr3)
        case "$2" in
            cmplx) run lab3/cmplx.sql ;;
            20)    run lab3/v20_vector3.sql ;;
            22)    run lab3/v22_rational.sql ;;
            *) echo "ОШИБКА: ./h lr3 cmplx|20|22"; exit 1 ;;
        esac
        ;;

    # ------------------------------ ЛР4 ------------------------------
    lr4)
        case "$2" in
            all)
                v=${3:-20}; need_variant "$v"
                [ -n "$4" ] && export LR4_WORK="$(cygpath -w "$4")"
                bat lab4/run_all.bat "$v" 2>&1 | perl helper/fixenc.pl | tee "results/lr4_v${v}_protocol.txt"
                ;;
            base)
                [ -n "$3" ] && export LR4_BASE="$3"
                bat lab4/create_base.bat 2>&1 | perl helper/fixenc.pl
                ;;
            tasks)
                if [ -z "$3" ]; then echo "Использование: ./h lr4 tasks N [база] [20|22]"; exit 1; fi
                # необязательные параметры в любом порядке: 20|22 - вариант, иначе - база
                db=""
                for a in "$4" "$5"; do
                    case "$a" in
                        '') ;;
                        20|22) export LR4_VARIANT="$a" ;;
                        *) if [ -n "$db" ]; then echo "ОШИБКА: две базы ($db, $a) - укажите базу и вариант 20|22"; exit 1; fi
                           db="$a" ;;
                    esac
                done
                bat lab4/tasks.bat "$3" "$db"
                ;;
            dump1|dump2)
                [ -n "$3" ] && export LR4_BASE="$3"
                bat "lab4/dump-${2#dump}.bat"
                ;;
            dump3)
                [ -n "$4" ] && export LR4_BASE="$4"
                bat lab4/dump-3.bat "$3"
                ;;
            *) echo "ОШИБКА: ./h lr4 all|base|tasks|dump1|dump2|dump3"; exit 1 ;;
        esac
        ;;

    # ------------------------------ ЛР5 ------------------------------
    lr5)
        case "$2" in
            build) need_variant "$3"; bat lab5/build.bat "$3" "${4:+$(cygpath -w "$4")}" 2>&1 | FIXENC_CP=cp866 perl helper/fixenc.pl ;;
            20|22) run "lab5/v$2_test.sql" "$3" ;;
            *) echo "ОШИБКА: ./h lr5 build 20|22  или  ./h lr5 20|22"; exit 1 ;;
        esac
        ;;

    # ------------------------------ ЛР6 ------------------------------
    lr6)
        case "$2" in
            setup)
                for f in create_DB create_temp1 insert_temp1 select_from_temp1; do
                    bat lab6/s_TCP.bat "lab6\\SETUP\\$f"
                done
                ;;
            sel2)     bat lab6/COPY/make_sel2.bat ;;
            createdb) bat lab6/s_TCP.bat 'lab6\COPY\create_DB' ;;
            copy)     bat lab6/COPY/copy_to_MS_SQL.bat 2>&1 | perl helper/fixenc.pl ;;
            disp)     bat lab6/COPY/disp.bat ;;
            v20|v22)
                need_task "$3"
                bat lab6/s.bat "lab6\\tasks\\$2_task$3.sql" "$4" "$5" "$6"
                ;;
            console)  bat lab6/s0.bat ;;
            *) echo "ОШИБКА: ./h lr6 setup|sel2|createdb|copy|disp|v20|v22|console"; exit 1 ;;
        esac
        ;;

    # ------------------------------ ЛР7 ------------------------------
    lr7)
        case "$2" in
            create) bat lab7/s.bat 'lab7\create_objects.sql' ;;
            1)      bat lab7/s.bat 'lab7\calculate1.sql' "$3" "$4" "$5" "$6" "$7" ;;
            2)      bat lab7/s.bat 'lab7\calculate2.sql' "$3" "$4" "$5" "$6" ;;
            *) echo "ОШИБКА: ./h lr7 create|1|2"; exit 1 ;;
        esac
        ;;

    # ------------------------------ ЛР8 ------------------------------
    lr8)
        case "$2" in
            build) bat lab8/v20/cs.bat "$3" 2>&1 | FIXENC_CP=cp866 perl helper/fixenc.pl ;;
            20)    shift 2; bat lab8/v20/run.bat "$@" ;;
            22)    shift 2; bat lab8/v22/run.bat "$@" ;;
            *) echo "ОШИБКА: ./h lr8 build|20|22"; exit 1 ;;
        esac
        ;;

    reports) shift; (cd reports && python make_reports.py "$@") ;;
    psql) psql -X ;;

    *) echo "ОШИБКА: Неизвестная команда $1 (./h - список команд)"; exit 1 ;;
esac
