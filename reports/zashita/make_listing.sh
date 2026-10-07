#!/bin/bash
# Листинг программы защиты ЛР2: все сценарии zashita/*.sql в порядке выполнения
# и фрагмент ./help (helper/help.ps1), который их запускает.
# Запуск из корня проекта: bash reports/zashita/make_listing.sh
cd "$(dirname "$0")/../.." || exit 1
out=reports/zashita/Листинг_программы.txt

section() {
    echo "------------------------------------------------------------------------------"
    echo "$1"
    echo "------------------------------------------------------------------------------"
}

{
    echo "=============================================================================="
    echo "ЗАЩИТА ЛАБОРАТОРНОЙ РАБОТЫ №2 - ЛИСТИНГ ПРОГРАММЫ (варианты 20 и 22)"
    echo "=============================================================================="
    echo
    echo "Запуск (PowerShell, корень проекта):"
    echo "  ./help zas 20 [all|1|2|3] [\"поставщик1\" \"поставщик2\"]   по умолчанию: ООО Турман, ЧП Загорье"
    echo "  ./help zas 22 [all|1|2|3] [категория]                     по умолчанию: мебель"
    echo "  ./help zas restore                                        вернуть PRIMARY KEY после защиты"
    echo
    echo "Порядок выполнения ./help zas NN (all):"
    echo "  helper/help.ps1 -> psql -> zashita/z_all.sql"
    echo "    z1_query.sql  задание 1: config.sql (параметры, vNN_query.sql -> :q),"
    echo "                  show_query.sql (текст запроса), :q (сводная таблица)"
    echo "    z2_noidx.sql  задание 2: drop_all.sql, [в.22: индекс ПРОДАЖА(товар)],"
    echo "                  show_query.sql, 5 x time_run.sql, time_table.sql"
    echo "    z3_idx.sql    задание 3: drop_all.sql, CREATE INDEX, таблица индексов,"
    echo "                  show_query.sql, time_run.sql (в.20 - 1 раз, в.22 - 5 раз),"
    echo "                  time_table.sql, EXPLAIN ANALYZE :q"
    echo "    итог          таблица минимального времени заданий 2 и 3"
    echo
    n=1
    for f in z_all.sql config.sql v20_query.sql v22_query.sql show_query.sql \
             z1_query.sql z2_noidx.sql z3_idx.sql drop_all.sql time_run.sql \
             time_table.sql indexes.sql show_idx.sql restore.sql; do
        section "$n. zashita/$f"
        cat "zashita/$f"
        echo
        n=$((n + 1))
    done
    section "$n. helper/help.ps1 - фрагмент: команда ./help zas"
    sed -n "/# защита ЛР2: запрос варианта/,/^    default {/p" helper/help.ps1 | sed '$d'
} > "$out"
echo "Листинг записан в $out ($(wc -l < "$out") строк)"
