#!/bin/bash
# Листинг программы защиты ЛР2: все сценарии big_db_indexes/def_*.sql в порядке выполнения
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
    echo "  ./help lr2 def 20 [all|1|2|3] [\"поставщик1\" \"поставщик2\"]   по умолчанию: ООО Турман, ЧП Загорье"
    echo "  ./help lr2 def 22 [all|1|2|3] [категория]                     по умолчанию: мебель"
    echo "  ./help lr2 def 20|22 idx|idx_drop|idx_add                     показать / удалить / создать индексы задания 3"
    echo "  ./help lr2 def restore                                        вернуть PRIMARY KEY после защиты"
    echo
    echo "Порядок выполнения ./help lr2 def NN (all):"
    echo "  helper/help.ps1 -> def_check_args.sql (проверка параметров) -> psql -> big_db_indexes/def_z_all.sql"
    echo "    def_config.sql    в каждой команде: параметры, def_vNN_query.sql -> :q; индексы другого"
    echo "                      варианта (def20_* / def22_*) удаляются - варианты независимы"
    echo "    def_z1_query.sql  задание 1: def_config.sql,"
    echo "                      def_show_query.sql (текст запроса), :q (сводная таблица)"
    echo "    def_z2_noidx.sql  задание 2: def_drop_all.sql, [в.22: индекс ПРОДАЖА(товар)],"
    echo "                      таблица индексов (в.20: индексов 0), def_show_query.sql, 5 x def_time_run.sql,"
    echo "                      def_time_table.sql, EXPLAIN ANALYZE :q, def_plan_check.sql (индексы в плане)"
    echo "    def_z3_idx.sql    задание 3: def_drop_all.sql, CREATE INDEX, таблица индексов,"
    echo "                      def_show_query.sql, 5 x def_time_run.sql,"
    echo "                      def_time_table.sql, EXPLAIN ANALYZE :q, def_plan_check.sql"
    echo "    итог              таблица минимального времени заданий 2 и 3"
    echo
    n=1
    for f in check_args.sql z_all.sql config.sql v20_query.sql v22_query.sql show_query.sql \
             z1_query.sql z2_noidx.sql z3_idx.sql drop_all.sql time_run.sql \
             time_table.sql plan_check.sql indexes.sql show_idx.sql idx_drop.sql idx_add.sql \
             restore.sql; do
        section "$n. big_db_indexes/def_$f"
        cat "big_db_indexes/def_$f"
        echo
        n=$((n + 1))
    done
    section "$n. helper/help.ps1 - фрагмент: команда ./help lr2 def"
    sed -n "/# защита ЛР2: .\/help lr2 def/,/^            default   {/p" helper/help.ps1 | sed '$d'
} > "$out"
echo "Листинг записан в $out ($(wc -l < "$out") строк)"
