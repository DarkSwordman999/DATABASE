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
    {
        local i=1
        for a in "$1" "$2" "$3"; do
            printf "\\\\set arg%d '%s'\n" "$i" "${a//\'/\'\'}"
            i=$((i + 1))
        done
        printf "\\\\i '%s'\n" "$file"
    } | psql -q -X -P pager=off -P "null=<null>" -f - 2>&1 | perl helper/fixenc.pl
}

# psql-сценарий в системной базе postgres (как s1.bat)
run_pg() {
    PGDATABASE=postgres psql -q -X -P pager=off -f "$1" 2>&1 | perl helper/fixenc.pl
}

# командный файл Windows: путь в формате Windows, параметры как есть
bat() {
    local file; file=$(cygpath -w "$1"); shift
    cmd.exe /c "$file" "$@"
}

need_variant() {
    if [ "$1" != "20" ] && [ "$1" != "22" ]; then
        echo "ОШИБКА: Укажите вариант 20 или 22"
        exit 1
    fi
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
    echo ""
    echo "================== ЛР1: БАЗА И ЗАДАНИЯ =================="
    echo "  ./h db              - создать БД sales, таблицы и загрузить данные"
    echo "  ./h counts          - количество строк в таблицах"
    echo "  ./h v20 1 [дата1 дата2 [категория]]  - в.20: объём поставок по категории и кварталу"
    echo "  ./h v20 2 [год1 год2 [день недели]]  - в.20: продажи (шт) по дню недели и району"
    echo "  ./h v22 1 [дата1 дата2 [поставщик]]  - в.22: выручка по поставщику и декаде"
    echo "  ./h v22 2 [год1 год2 [время года]]   - в.22: затраты клиентов по сезону и полу"
    echo "  ./h all             - все 4 задания с параметрами по умолчанию"
    echo "  Пример: ./h v20 1 01.01.2021 31.12.2022 мебель"
    echo ""
    echo "================== ЛР2: ОБЪЁМНАЯ БД, ИНДЕКСЫ, EXPLAIN =================="
    echo "  ./h lr2 gen [N]           - ПРОДАЖА: N псевдослучайных записей (по умолч. 2 000 000)"
    echo "  ./h lr2 restore           - вернуть 1000 записей ПРОДАЖА из ЛР1"
    echo "  ./h lr2 tbs [каталог]     - вынести ПРОДАЖА в табличное пространство (D:/PG_TBS)"
    echo "  ./h lr2 time 20|22        - время запроса (*) по CURRENT_TIME, 5 замеров"
    echo "  ./h lr2 timing 20|22      - время запроса (*) по \\timing on, 5 замеров"
    echo "  ./h lr2 idx 20|22         - индексы ПРОДАЖА и таблицы-справочника"
    echo "  ./h lr2 idx1 20|22 [btree|hash] - создать индекс ПРОДАЖА по полю-ссылке"
    echo "  ./h lr2 idx0 20|22        - удалить индекс ПРОДАЖА по полю-ссылке"
    echo "  ./h lr2 pk1 20|22         - справочник с PRIMARY KEY (create_ref0)"
    echo "  ./h lr2 pk0 20|22         - справочник без PRIMARY KEY (create_ref1)"
    echo "  ./h lr2 copy 20|22        - перезагрузить справочник из DATA/SOURCE"
    echo "  ./h lr2 explain 20|22 [1] - EXPLAIN / EXPLAIN ANALYZE (1 - с WHERE)"
    echo "  ./h lr2 measure 20|22 [прогонов] - протокол замеров -> results/lr2_vNN_results.txt"
    echo "  ./h lr2 results 20|22     - показать протокол замеров"
    echo ""
    echo "================== ЛР3: ПОЛЬЗОВАТЕЛЬСКИЕ ТИПЫ =================="
    echo "  ./h lr3 cmplx             - пример преподавателя (complex)"
    echo "  ./h lr3 20                - в.20: трёхмерный вектор (vector3)"
    echo "  ./h lr3 22                - в.22: рациональное число (rational)"
    echo ""
    echo "================== ЛР4: РЕЗЕРВНОЕ КОПИРОВАНИЕ =================="
    echo "  ./h lr4 all               - пп. 1-10 целиком -> results/lr4_protocol.txt"
    echo "  ./h lr4 base              - создать базу BASE из данных ЛР1"
    echo "  ./h lr4 tasks N [база]    - контрольные задачи -> taskN-01..03"
    echo "  ./h lr4 dump1|dump2|dump3 - pg_dump в файл / rar / многотомный rar"
    echo "  (каталог копий: lab4/work или LR4_WORK=D:/LR4_WORK ./h lr4 all)"
    echo ""
    echo "================== ЛР5: ФУНКЦИИ НА C =================="
    echo "  ./h lr5 build 20|22       - компиляция и сборка vNN.dll (-> D:\\PG_DLL)"
    echo "  ./h lr5 20|22 [каталог]   - регистрация функций и демонстрация на таблице T"
    echo ""
    echo "================== ЛР6: КОПИРОВАНИЕ В MS SQL SERVER =================="
    echo "  ./h lr6 setup             - проверка сервера (база NEW1, таблица temp1)"
    echo "  ./h lr6 sel2              - собрать фильтр sel2.exe"
    echo "  ./h lr6 createdb          - создать базу SALES в MS SQL Server"
    echo "  ./h lr6 copy              - скопировать все таблицы sales из PostgreSQL"
    echo "  ./h lr6 disp              - проверить скопированные таблицы"
    echo "  ./h lr6 v20|v22 1|2 [параметры] - задания варианта в MS SQL Server"
    echo "  ./h lr6 console           - консоль sqlcmd"
    echo ""
    echo "================== ЛР7: ПРЕДСТАВЛЕНИЯ И ФУНКЦИИ MS SQL SERVER =================="
    echo "  ./h lr7 create            - создать представления и функции"
    echo "  ./h lr7 1 [D1 D2 P M [N]] - премия сотрудников (N - имя сотрудника)"
    echo "  ./h lr7 2 [D1 D2 alpha [G]] - затраты на хранение (G - товар)"
    echo "  Пример: ./h lr7 1 01.01.2021 30.06.2021 8.5 10.5 Иван"
    echo ""
    echo "================== ПРОЧЕЕ =================="
    echo "  ./h psql                  - консоль psql (база sales)"
    echo "  ./h файл.sql [a1 [a2 [a3]]] - выполнить любой psql-сценарий с параметрами"
    exit 1
fi

if [[ "$1" == *.sql ]]; then
    f="$1"; shift
    run "$f" "$@"
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
                bat lab4/run_all.bat 2>&1 | perl helper/fixenc.pl | tee results/lr4_protocol.txt
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
            build) need_variant "$3"; bat lab5/build.bat "$3" "$4" ;;
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

    psql) psql -X ;;
    *) echo "ОШИБКА: Неизвестная команда $1 (./h - список команд)" ;;
esac
