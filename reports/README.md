# 📄 reports — отчёты, руководство и вывод прогонов

Отчёты по всем работам собираются автоматически из сценариев репозитория и **реального** вывода команд `./help`: сначала вывод снимается в [`out/`](out), затем генераторы оформляют `.docx` (титульный лист ТулГУ, разделы, листинги, таблицы).

[← к общему описанию проекта](../README.md)

## Что здесь лежит

| Файл / папка | Назначение |
|---|---|
| [`docx/`](docx) | 16 отчётов `ЛРn_вариант_NN.docx` (8 работ × варианты 20 и 22) и [`Руководство_по_сценарию_help.docx`](docx/Руководство_по_сценарию_help.docx) |
| [`out/`](out) | сохранённый вывод команд, из которого берутся результаты в отчётах (первая строка — команда `./help …`) |
| [`zashita/`](zashita) | защита ЛР2: отчёты `Защита_вариант_20.txt`, `Защита_вариант_22.txt` и `Листинг_программы.txt` |
| [`capture.sh`](capture.sh) | снять вывод команд в `out/`: `bash reports/capture.sh [lr1\|lr2\|lr3\|lr5\|lr6\|lr7\|lr8\|help ...]` |
| [`make_reports.py`](make_reports.py) | собрать отчёты: `python reports/make_reports.py [номер ЛР ...]` |
| [`make_help_doc.py`](make_help_doc.py) | собрать руководство по сценарию `./help`: таблицы команд строятся из справки `helper/help.ps1` и `helper/menu.txt` |
| [`docgen.py`](docgen.py) | общее оформление документов (python-docx) |
| [`check_reports.py`](check_reports.py) | проверка отчётов: обязательные разделы, номер варианта, пустые листинги |
| [`zashita/make_defense.py`](zashita/make_defense.py), [`zashita/make_listing.sh`](zashita/make_listing.sh) | отчёты защиты ЛР2 из протоколов [`../results/zas_*`](../results) и листинг программы |

## Порядок сборки

```bash
bash reports/capture.sh                 # вывод всех работ (кроме ЛР2: bash reports/capture.sh lr2 - перегенерирует 2 млн продаж)
python reports/make_reports.py          # 16 отчётов;  python reports/make_reports.py 3 - только ЛР3
python reports/make_help_doc.py         # руководство
python reports/check_reports.py         # проверка
python reports/zashita/make_defense.py  # отчёты защиты ЛР2;  bash reports/zashita/make_listing.sh - листинг
```

Нужен Python с пакетом `python-docx`. Каждый отчёт содержит цель, задание, ход работы с листингами сценариев и выводом, раздел «Защита работы: запуск через ./help» (команды, справка по ЛР, фрагмент сценария), выводы и приложение — листинг `help.ps1`. В отчёте ЛР3 есть раздел «Задание на защиту».
