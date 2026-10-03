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
run() {
    local file="$1"; shift
    if [ ! -f "$file" ]; then
        echo "ОШИБКА: Файл $file не найден"
        exit 1
    fi
    echo ">>> Файл: $file"
    {
        local i=1
        for a in "$1" "$2" "$3" "$4" "$5"; do
            printf "\\\\set arg%d '%s'\n" "$i" "${a//\'/\'\'}"
            i=$((i + 1))
        done
        printf "\\\\i '%s'\n" "$file"
    } | psql -q -X -P pager=off -P "null=<null>" -f - 2>&1 | perl helper/fixenc.pl
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

need_variant() {
    if [ "$1" != "20" ] && [ "$1" != "22" ]; then
        echo "ОШИБКА: Укажите вариант 20 или 22"
        exit 1
    fi
}

# команды-аналоги TAXI-db: таблица helper/menu.txt (код|файл|параметры|обязательных|описание)
show_menu() {
    local code file params req desc ex cmd pad
    local LC_ALL=C.UTF-8     # длина строки ${#cmd} - в символах, а не в байтах
    while IFS='|' read -r code file params req desc ex; do
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

if [ -z "$1" ]; then
    echo "============================================="
    echo "  ПАБД: БАЗА ДАННЫХ SALES, ВАРИАНТЫ 20 И 22"
    echo "============================================="
    echo "  В [] - файл, который выполняет команда; при запуске он выводится строкой \">>> Файл: ...\"."
    echo "  Обработчик каждой команды - сценарий h (case, ветвь с именем команды)."
    echo ""
    echo "================== ЛР1: БАЗА И ЗАДАНИЯ =================="
    echo "  ./h db              - создать БД sales, таблицы и загрузить данные  [DATA/create_DB, DATA/create_tables, DATA/load_data]"
    echo "  ./h counts          - количество строк в таблицах  [helper/counts.sql]"
    echo "  ./h v20 1 [дата1 дата2 [категория]]  - в.20: объём поставок по категории и кварталу  [tasks/v20_task1.sql]"
    echo "  ./h v20 2 [год1 год2 [день недели]]  - в.20: продажи (шт) по дню недели и району  [tasks/v20_task2.sql]"
    echo "  ./h v22 1 [дата1 дата2 [поставщик]]  - в.22: выручка по поставщику и декаде  [tasks/v22_task1.sql]"
    echo "  ./h v22 2 [год1 год2 [время года]]   - в.22: затраты клиентов по сезону и полу  [tasks/v22_task2.sql]"
    echo "  ./h all             - все 4 задания с параметрами по умолчанию  [tasks/*.sql]"
    echo "  ./h lr1 lan         - настроить pg_hba.conf и брандмауэр для сети (от администратора)  [lab1/setup_lan.ps1]"
    echo "  ./h lr1 client сценарий [a1 a2 a3] - выполнить сценарий через s_lan.bat (сервер по IP)  [lab1/s_lan.bat]"
    echo "  ./h srv [check]     - сервер в сети PMII (192.168.1.50, stud): подключение и таблицы  [lab1/check_server.sql]"
    echo "  ./h srv v20|v22 1|2 [параметры] - задание варианта на сервере в сети  [tasks/vNN_taskN.sql]"
    echo "  ./h srv all         - проверка и все 4 задания на сервере; ./h srv psql - консоль"
    echo "  (другой адрес/пользователь: SRV_HOST, SRV_PORT, SRV_USER, SRV_PASS)"
    echo "  Пример: ./h v20 1 01.01.2021 31.12.2022 мебель"
    echo ""
    echo "================== ЛР2: ОБЪЁМНАЯ БД, ИНДЕКСЫ, EXPLAIN =================="
    echo "  ./h lr2 gen [N]           - ПРОДАЖА: N псевдослучайных записей (по умолч. 2 000 000)  [lab2/add_data.sql]"
    echo "  ./h lr2 restore           - вернуть 1000 записей ПРОДАЖА из ЛР1  [lab2/restore_lr1.sql]"
    echo "  ./h lr2 tbs [каталог]     - вынести ПРОДАЖА в табличное пространство (D:/PG_TBS)  [lab2/tablespace.sql]"
    echo "  ./h lr2 time 20|22        - время запроса (*) по CURRENT_TIME, 5 замеров  [lab2/time_current.sql]"
    echo "  ./h lr2 timing 20|22      - время запроса (*) по \\timing on, 5 замеров  [lab2/time_timing.sql]"
    echo "  ./h lr2 idx 20|22         - индексы ПРОДАЖА и таблицы-справочника  [lab2/idx_names.sql]"
    echo "  ./h lr2 idx1 20|22 [btree|hash] - создать индекс ПРОДАЖА по полю-ссылке  [lab2/idx_1.sql]"
    echo "  ./h lr2 idx0 20|22        - удалить индекс ПРОДАЖА по полю-ссылке  [lab2/idx_0.sql]"
    echo "  ./h lr2 pk1 20|22         - справочник с PRIMARY KEY  [lab2/create_ref0.sql]"
    echo "  ./h lr2 pk0 20|22         - справочник без PRIMARY KEY  [lab2/create_ref1.sql]"
    echo "  ./h lr2 copy 20|22        - перезагрузить справочник из DATA/SOURCE  [lab2/copy_ref.sql]"
    echo "  ./h lr2 explain 20|22 [1] - EXPLAIN / EXPLAIN ANALYZE (1 - с WHERE)  [lab2/explain.sql]"
    echo "  ./h lr2 measure 20|22 [прогонов] - протокол замеров -> results/lr2_vNN_results.txt  [lab2/measure.sql]"
    echo "  ./h lr2 results 20|22     - показать протокол замеров  [results/lr2_vNN_results.txt]"
    echo "  (запрос (*) и настройки варианта: lab2/vNN_query.sql, lab2/vNN_config.sql, lab2/config.sql)"
    echo ""
    echo "================== ЗАЩИТА ЛР2: ИНДЕКСЫ И ВРЕМЯ ЗАПРОСА =================="
    echo "  ./h zas 20 [all] [\"поставщик1\" \"поставщик2\"] - в.20: задания 1-3 подряд  [zashita/z_all.sql]"
    echo "  ./h zas 22 [all] [категория]  - в.22: задания 1-3 подряд  [zashita/z_all.sql]"
    echo "  ./h zas 20|22 1 [параметры]   - 1) запрос варианта и результат  [zashita/z1_query.sql, zashita/vNN_query.sql]"
    echo "  ./h zas 20|22 2 [параметры]   - 2) без индексов (никаких): 5 замеров, мс и мин, минимум  [zashita/z2_noidx.sql]"
    echo "  ./h zas 20|22 3 [параметры]   - 3) индексы варианта, замер(ы) и EXPLAIN ANALYZE  [zashita/z3_idx.sql]"
    echo "  ./h zas 20|22 idx             - индексы таблиц запроса варианта  [zashita/show_idx.sql]"
    echo "  ./h zas restore               - удалить индексы защиты, вернуть PRIMARY KEY  [zashita/restore.sql]"
    echo "  (нужна объёмная ПРОДАЖА: ./h lr2 gen; в.20 по умолч. \"ООО Турман\" \"ЧП Загорье\", в.22 - мебель)"
    echo ""
    echo "================== ЛР3: ПОЛЬЗОВАТЕЛЬСКИЕ ТИПЫ =================="
    echo "  ./h lr3 cmplx             - пример преподавателя (complex)  [lab3/cmplx.sql]"
    echo "  ./h lr3 20                - в.20: трёхмерный вектор (vector3)  [lab3/v20_vector3.sql]"
    echo "  ./h lr3 22                - в.22: рациональное число (rational)  [lab3/v22_rational.sql]"
    echo ""
    echo "================== ЛР4: РЕЗЕРВНОЕ КОПИРОВАНИЕ =================="
    echo "  ./h lr4 all [20|22]       - пп. 1-10 целиком -> results/lr4_vNN_protocol.txt  [lab4/run_all.bat]"
    echo "  ./h lr4 base              - создать базу BASE из данных ЛР1  [lab4/create_base.bat]"
    echo "  ./h lr4 tasks N [база]    - контрольные задачи -> taskN-01..03  [lab4/tasks.bat]"
    echo "  ./h lr4 dump1|dump2|dump3 - pg_dump в файл / rar / многотомный rar  [lab4/dump-1.bat, dump-2.bat, dump-3.bat]"
    echo "  (каталог копий: lab4/work или LR4_WORK=D:/LR4_WORK ./h lr4 all)"
    echo ""
    echo "================== ЛР5: ФУНКЦИИ НА C =================="
    echo "  ./h lr5 build 20|22       - компиляция и сборка vNN.dll (-> D:\\PG_DLL)  [lab5/build.bat]"
    echo "  ./h lr5 20|22 [каталог]   - регистрация функций и демонстрация на таблице T  [lab5/vNN_test.sql]"
    echo ""
    echo "================== ЛР6: КОПИРОВАНИЕ В MS SQL SERVER =================="
    echo "  ./h lr6 setup             - проверка сервера (база NEW1, таблица temp1)  [lab6/s_TCP.bat + lab6/SETUP/*]"
    echo "  ./h lr6 sel2              - собрать фильтр sel2.exe  [lab6/COPY/make_sel2.bat]"
    echo "  ./h lr6 createdb          - создать базу SALES в MS SQL Server  [lab6/COPY/create_DB]"
    echo "  ./h lr6 copy              - скопировать все таблицы sales из PostgreSQL  [lab6/COPY/copy_to_MS_SQL.bat]"
    echo "  ./h lr6 disp              - проверить скопированные таблицы  [lab6/COPY/disp.bat]"
    echo "  ./h lr6 v20|v22 1|2 [параметры] - задания варианта в MS SQL Server  [lab6/tasks/vNN_taskN.sql]"
    echo "  ./h lr6 console           - консоль sqlcmd  [lab6/s0.bat]"
    echo ""
    echo "================== ЛР7: ПРЕДСТАВЛЕНИЯ И ФУНКЦИИ MS SQL SERVER =================="
    echo "  ./h lr7 create            - создать представления и функции  [lab7/create_objects.sql]"
    echo "  ./h lr7 1 [D1 D2 P M [N]] - премия сотрудников (N - имя сотрудника)  [lab7/calculate1.sql]"
    echo "  ./h lr7 2 [D1 D2 alpha [G]] - затраты на хранение (G - товар)  [lab7/calculate2.sql]"
    echo "  Пример: ./h lr7 1 01.01.2021 30.06.2021 8.5 10.5 Иван"
    echo ""
    echo "================== ЛР8: ПРОГРАММЫ С ДАННЫМИ MS SQL SERVER =================="
    echo "  ./h lr8 build             - компиляция программы C# варианта 20  [lab8/v20/cs.bat]"
    echo "  ./h lr8 20 [D1 D2 [категория]] - в.20 (C#): продажи (шт) по категории и кварталу  [lab8/v20/run.bat]"
    echo "  ./h lr8 22 [D1 D2 [поставщик]] - в.22 (Python): затраты клиентов по поставщику и декаде  [lab8/v22/run.bat]"
    show_menu
    echo ""
    echo "================== ЗАПУСК SQL-ФАЙЛОВ =================="
    echo "  ./h файл.sql [a1 .. a5]   - выполнить любой psql-сценарий с параметрами arg1..arg5"
    echo "  ./h psql                  - консоль psql (база sales)"
    echo "  ./h reports [N ...]       - пересобрать отчёты .docx  [reports/make_reports.py]"
    exit 1
fi

if [[ "$1" == *.sql ]]; then
    f="$1"; shift
    run "$f" "$@"
    exit 0
fi

# команды-аналоги TAXI-db (./h 01 ... ./h 204): файл и параметры - из helper/menu.txt
if [[ "$1" =~ ^[0-9]+$ ]] && line=$(grep -m1 "^$1|" helper/menu.txt); then
    IFS='|' read -r code file params req desc ex <<< "$line"
    shift
    given=0
    for a in "$@"; do [ -n "$a" ] && given=$((given + 1)); done
    if [ "$given" -lt "$req" ]; then
        echo "Использование: ./h $code $params   ($desc)"
        [ -n "$ex" ] && echo "Пример:        ./h $code $ex"
        exit 1
    fi
    echo ">>> ./h $code - $desc"
    run "$file" "$@"
    exit 0
fi

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
            lan)    powershell -ExecutionPolicy Bypass -File lab1/setup_lan.ps1 ;;
            client)
                if [ -z "$3" ]; then echo "Использование: ./h lr1 client сценарий [a1 a2 a3]"; exit 1; fi
                bat lab1/s_lan.bat "$(cygpath -w "$3")" "$4" "$5" "$6"
                ;;
            *) echo "ОШИБКА: ./h lr1 lan|client" ;;
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
        echo "Сервер: $PGHOST:$PGPORT, база $PGDATABASE, пользователь $PGUSER"
        case "$2" in
            ""|check) run lab1/check_server.sql ;;
            v20|v22)
                need_task "$3"
                run "tasks/$2_task$3.sql" "$4" "$5" "$6"
                ;;
            all)
                run lab1/check_server.sql
                for t in v20_task1 v20_task2 v22_task1 v22_task2; do
                    run "tasks/$t.sql"
                done
                ;;
            psql) psql ;;
            *) echo "ОШИБКА: ./h srv [check|all|psql|v20 N|v22 N [параметры]]" ;;
        esac
        ;;

    # ------------------------------ ЛР2 ------------------------------
    lr2)
        case "$2" in
            gen)      run lab2/add_data.sql "$3" ;;
            restore)  run lab2/restore_lr1.sql ;;
            tbs)      run lab2/tablespace.sql "$3" ;;
            time)     need_variant "$3"; run lab2/time_current.sql "$3" ;;
            timing)   need_variant "$3"; run lab2/time_timing.sql "$3" ;;
            idx)      need_variant "$3"; run lab2/idx_names.sql "$3" ;;
            idx1)     need_variant "$3"; run lab2/idx_1.sql "$3" "$4" ;;
            idx0)     need_variant "$3"; run lab2/idx_0.sql "$3" ;;
            pk1)      need_variant "$3"; run lab2/create_ref0.sql "$3" ;;
            pk0)      need_variant "$3"; run lab2/create_ref1.sql "$3" ;;
            copy)     need_variant "$3"; run lab2/copy_ref.sql "$3" ;;
            explain)  need_variant "$3"; run lab2/explain.sql "$3" "$4" ;;
            measure)  need_variant "$3"; run lab2/measure.sql "$3" "$4"
                      cat "results/lr2_v$3_results.txt" ;;
            results)  need_variant "$3"; cat "results/lr2_v$3_results.txt" ;;
            *) echo "ОШИБКА: ./h lr2 gen|restore|tbs|time|timing|idx|idx1|idx0|pk1|pk0|copy|explain|measure|results" ;;
        esac
        ;;

    # ------------------------------ ЛР3 ------------------------------
    lr3)
        case "$2" in
            cmplx) run lab3/cmplx.sql ;;
            20)    run lab3/v20_vector3.sql ;;
            22)    run lab3/v22_rational.sql ;;
            *) echo "ОШИБКА: ./h lr3 cmplx|20|22" ;;
        esac
        ;;

    # ------------------------------ ЛР4 ------------------------------
    lr4)
        case "$2" in
            all)
                v=${3:-20}; need_variant "$v"
                bat lab4/run_all.bat "$v" 2>&1 | perl helper/fixenc.pl | tee "results/lr4_v${v}_protocol.txt"
                ;;
            base)  bat lab4/create_base.bat 2>&1 | perl helper/fixenc.pl ;;
            tasks)
                if [ -z "$3" ]; then echo "Использование: ./h lr4 tasks N [база]"; exit 1; fi
                bat lab4/tasks.bat "$3" "$4"
                ;;
            dump1) bat lab4/dump-1.bat ;;
            dump2) bat lab4/dump-2.bat ;;
            dump3) bat lab4/dump-3.bat "$3" ;;
            *) echo "ОШИБКА: ./h lr4 all|base|tasks|dump1|dump2|dump3" ;;
        esac
        ;;

    # ------------------------------ ЛР5 ------------------------------
    lr5)
        case "$2" in
            build) need_variant "$3"; bat lab5/build.bat "$3" "$4" 2>&1 | FIXENC_CP=cp866 perl helper/fixenc.pl ;;
            20|22) run "lab5/v$2_test.sql" "$3" ;;
            *) echo "ОШИБКА: ./h lr5 build 20|22  или  ./h lr5 20|22" ;;
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
            *) echo "ОШИБКА: ./h lr6 setup|sel2|createdb|copy|disp|v20|v22|console" ;;
        esac
        ;;

    # ------------------------------ ЛР7 ------------------------------
    lr7)
        case "$2" in
            create) bat lab7/s.bat 'lab7\create_objects.sql' ;;
            1)      bat lab7/s.bat 'lab7\calculate1.sql' "$3" "$4" "$5" "$6" "$7" ;;
            2)      bat lab7/s.bat 'lab7\calculate2.sql' "$3" "$4" "$5" "$6" ;;
            *) echo "ОШИБКА: ./h lr7 create|1|2" ;;
        esac
        ;;

    # ------------------------------ ЛР8 ------------------------------
    lr8)
        case "$2" in
            build) bat lab8/v20/cs.bat 2>&1 | FIXENC_CP=cp866 perl helper/fixenc.pl ;;
            20)    shift 2; bat lab8/v20/run.bat "$@" ;;
            22)    shift 2; bat lab8/v22/run.bat "$@" ;;
            *) echo "ОШИБКА: ./h lr8 build|20|22" ;;
        esac
        ;;

    reports) shift; (cd reports && python make_reports.py "$@") ;;
    psql) psql -X ;;

    # защита ЛР2: запрос варианта без индексов и с индексами (zashita/*.sql)
    zas)
        if [ "$2" = "restore" ]; then run zashita/restore.sql; exit 0; fi
        need_variant "$2"
        step=${3:-all}
        case "$step" in
            all) f=zashita/z_all.sql ;;
            1)   f=zashita/z1_query.sql ;;
            2)   f=zashita/z2_noidx.sql ;;
            3)   f=zashita/z3_idx.sql ;;
            idx) run zashita/show_idx.sql "$2"; exit 0 ;;
            *)   echo "ОШИБКА: ./h zas 20|22 [all|1|2|3|idx] [параметры]  или  ./h zas restore"; exit 1 ;;
        esac
        if [ "$step" = "all" ] || [ "$step" = "1" ]; then
            echo ">>> Текст запроса: zashita/v$2_query.sql"
            cat "zashita/v$2_query.sql"
        fi
        run "$f" "$2" "$4" "$5"
        ;;
    *) echo "ОШИБКА: Неизвестная команда $1 (./h - список команд)" ;;
esac
