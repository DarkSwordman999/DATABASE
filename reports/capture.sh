#!/bin/bash
# Сбор реального вывода сценариев для отчётов: reports/out/*.txt
# Запуск из корня проекта: bash reports/capture.sh [lr1|lr2|lr3|lr5|lr6|lr7|lr8|help ...]
# ЛР2 требует объёмной таблицы ПРОДАЖА (./help lr2 gen), ЛР1/ЛР6/ЛР7 - данных ЛР1 (./help lr2 restore)
cd "$(dirname "$0")/.." || exit 1
O=${CAPTURE_OUT:-reports/out}
mkdir -p "$O"

# команды выполняются сценарием help (PowerShell: help.cmd -> helper/help.ps1)
cap() {                 # cap <файл> <команда...>: вывод команды с строкой вызова
    local f="$1"; shift
    { echo "> ./help $*"
      powershell.exe -NoProfile -ExecutionPolicy Bypass -File helper/help.ps1 "$@" 2>&1
    } > "$O/$f.txt"
    echo "  $f"
}

want() { [ $# -eq 0 ] || [[ " $ARGS " == *" $1 "* ]]; }
ARGS="$*"

if [ -z "$ARGS" ] || want lr1; then
    echo "ЛР1"
    cap lr1_counts counts
    cap lr1_v20_1 v20 1
    cap lr1_v20_1p v20 1 01.01.2021 31.12.2022 мебель
    cap lr1_v20_2 v20 2
    cap lr1_v20_2p v20 2 2019 2023 пт
    cap lr1_v22_1 v22 1
    cap lr1_v22_1p v22 1 01.01.2020 31.12.2020 "ООО Турман"
    cap lr1_v22_2 v22 2
    cap lr1_v22_2p v22 2 2018 2022 зима
fi
if [ -z "$ARGS" ] || want lr3; then
    echo "ЛР3"
    cap lr3_cmplx lr3 cmplx
    cap lr3_20 lr3 20
    cap lr3_22 lr3 22
fi
if [ -z "$ARGS" ] || want lr5; then
    echo "ЛР5"
    cap lr5_build20 lr5 build 20
    cap lr5_build22 lr5 build 22
    cap lr5_20 lr5 20
    cap lr5_22 lr5 22
fi
if [ -z "$ARGS" ] || want lr6; then
    echo "ЛР6"
    cap lr6_setup lr6 setup
    cap lr6_createdb lr6 createdb
    cap lr6_copy lr6 copy
    cap lr6_disp lr6 disp
    for v in v20 v22; do for t in 1 2; do cap "lr6_${v}_$t" lr6 $v $t; done; done
    cap lr6_v20_1p lr6 v20 1 01.01.2021 31.12.2022 мебель
    cap lr6_v22_1p lr6 v22 1 01.01.2020 31.12.2020 "ООО Турман"
    iconv -f cp1251 -t utf-8 lab6/COPY/cr_ТОВАР.txt > "$O/lr6_cr_tovar.txt"
    iconv -f cp1251 -t utf-8 lab6/COPY/cr_ПРОДАЖА.txt > "$O/lr6_cr_prodazha.txt"
    head -5 lab6/COPY/d_ПРОДАЖА.txt | iconv -f cp1251 -t utf-8 > "$O/lr6_d_prodazha.txt"
fi
if [ -z "$ARGS" ] || want lr7; then
    echo "ЛР7"
    cap lr7_create lr7 create
    # вариант 20
    cap lr7_v20_1a lr7 1 01.01.2021 30.06.2021 8.5 10.5
    cap lr7_v20_1b lr7 1 01.01.2021 30.06.2021 8.5 10.5 Андрей
    cap lr7_v20_2a lr7 2 01.01.2021 30.06.2021 0.5
    cap lr7_v20_2b lr7 2 01.01.2021 30.06.2021 0.5 плащ
    cap lr7_v20_2c lr7 2 01.01.2022 31.03.2022 1 диван
    # вариант 22
    cap lr7_v22_1a lr7 1 01.07.2022 31.12.2022 7.5 12
    cap lr7_v22_1b lr7 1 01.07.2022 31.12.2022 7.5 12 Ольга
    cap lr7_v22_2a lr7 2 01.07.2022 31.12.2022 0.5
    cap lr7_v22_2b lr7 2 01.07.2022 31.12.2022 0.5 шкаф
    cap lr7_v22_2c lr7 2 01.01.2023 31.03.2023 0 костюм
    # проверка по эталону bonus3 (общая для вариантов)
    cap lr7_check lr7 1 01.01.2018 31.12.2024 10 10
fi
if [ -z "$ARGS" ] || want lr8; then
    echo "ЛР8"
    cap lr8_build lr8 build
    cap lr8_20a lr8 20
    cap lr8_20b lr8 20 01.01.2021 31.12.2021
    cap lr8_20c lr8 20 01.07.2019 30.06.2023 мебель
    cap lr8_22a lr8 22
    cap lr8_22b lr8 22 01.01.2022 31.12.2022
    cap lr8_22c lr8 22 01.10.2021 31.01.2024 "ООО Турман"
fi
# руководство по сценарию (reports/make_help_doc.py): справка и проверка параметров,
# только команды без изменения данных
if [ -z "$ARGS" ] || want help; then
    echo "help"
    cap help_short short
    cap help_short3 short 3
    cap help_menu17 17
    cap help_err_period v20 1 01.01.2023 01.01.2021
    cap help_err_date v20 1 31.02.2021 31.12.2021
    cap help_err_prov v22 1 01.07.2019 30.06.2023 "ООО Тур"
    cap help_err_variant lr2 time 21
    cap help_err_extra lr2 def 20 idx лишний
    cap help_err_cmd abc
fi
if want lr2; then
    echo "ЛР2"
    cap lr2_gen lr2 gen
    for v in 20 22; do
        cap "lr2_time_$v" lr2 time $v
        cap "lr2_timing_$v" lr2 timing $v
        cap "lr2_idx_$v" lr2 idx $v
        cap "lr2_idx1_$v" lr2 idx1 $v btree
        cap "lr2_explain_$v" lr2 explain $v 1
        cap "lr2_idx0_$v" lr2 idx0 $v
        cap "lr2_pk0_$v" lr2 pk0 $v
        cap "lr2_pk1_$v" lr2 pk1 $v
    done
fi
