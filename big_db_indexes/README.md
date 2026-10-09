# ⏱️ big_db_indexes — ЛР2: время запросов в объёмной БД и индексы

ЛР2 «Оценка временных характеристик выполнения запросов в объёмной базе данных PostgreSQL»: таблица `ПРОДАЖА` базы [SALES](../DATA) увеличивается до 2 000 000 записей, измеряется время запроса (*) при разных индексах и ключах, план разбирается командой `EXPLAIN ANALYZE`. Файлы `def_*.sql` — защита ЛР2.

[← к общему описанию проекта](../README.md)

## Варианты

| | Вариант 20 | Вариант 22 |
|---|---|---|
| Таблица-справочник | `ТОВАР` | `МАГАЗИН` |
| Поле-ссылка в `ПРОДАЖА` | `товар` | `магазин` |
| Условие запроса (*) с WHERE | `ТОВАР.категория = 1` (половина товаров) | `МАГАЗИН.название = 'Весна'` (1 магазин из 5) |

## Файлы ЛР2

| Файл | Назначение |
|---|---|
| [`add_data.sql`](add_data.sql) | `ПРОДАЖА`: N псевдослучайных записей (по умолчанию 2 000 000) |
| [`restore_lr1.sql`](restore_lr1.sql) | вернуть 1000 записей ЛР1 |
| [`tablespace.sql`](tablespace.sql) | вынести `ПРОДАЖА` в табличное пространство (по умолчанию `D:/PG_TBS`) |
| [`config.sql`](config.sql), [`v20_config.sql`](v20_config.sql), [`v22_config.sql`](v22_config.sql) | настройки варианта: справочник, поле-ссылка, условие |
| [`v20_query.sql`](v20_query.sql), [`v22_query.sql`](v22_query.sql) | запрос (*) варианта |
| [`time_current.sql`](time_current.sql) (`_run`, `_rep`) | время по `CURRENT_TIME`, N замеров |
| [`time_timing.sql`](time_timing.sql) (`_rep`) | время по `\timing on`, N замеров |
| [`idx_names.sql`](idx_names.sql), [`idx_1.sql`](idx_1.sql), [`idx_0.sql`](idx_0.sql) | показать / создать (btree или hash) / удалить индекс `ПРОДАЖА` по полю-ссылке |
| [`create_ref0.sql`](create_ref0.sql), [`create_ref1.sql`](create_ref1.sql), [`copy_ref.sql`](copy_ref.sql) | справочник с PRIMARY KEY / без него / перезагрузка из `DATA/SOURCE` |
| [`explain.sql`](explain.sql) | `EXPLAIN` и `EXPLAIN ANALYZE` (с WHERE и без) |
| [`measure.sql`](measure.sql) | протокол замеров по всем сочетаниям → [`../results/lr2_vNN_results.txt`](../results) |

## Запуск ЛР2

```powershell
./help lr2 gen                 # 2 млн записей в ПРОДАЖА (./help lr2 gen 500000 - другое число)
./help lr2 tbs D:/PG_TBS       # табличное пространство
./help lr2 time 20 5           # время запроса (*) по CURRENT_TIME, 5 замеров;   ./help lr2 time 22 10
./help lr2 timing 22           # время по \timing on
./help lr2 idx1 20 btree       # индекс ПРОДАЖА по полю-ссылке;  ./help lr2 idx1 22 hash
./help lr2 idx 20              # индексы ПРОДАЖА и справочника;  ./help lr2 idx0 22 - удалить
./help lr2 pk0 20              # справочник без PRIMARY KEY;     ./help lr2 pk1 22 - с ключом
./help lr2 explain 20 1        # EXPLAIN ANALYZE с WHERE;        ./help lr2 explain 22
./help lr2 measure 22 3        # протокол замеров, 3 прогона
./help lr2 results 20          # показать протокол
./help lr2 restore             # вернуть данные ЛР1
```

## Результаты ЛР2

`ПРОДАЖА` — 2 000 000 записей (100 MB) в табличном пространстве на диске D:. Время запроса (*): **≈3.1 с** (в.20), **≈4.2 с** (в.22) — в требуемом диапазоне 0.5–10 с. Протоколы: [`../results/lr2_v20_results.txt`](../results/lr2_v20_results.txt), [`../results/lr2_v22_results.txt`](../results/lr2_v22_results.txt).

- **в.20**: условие отбирает половину строк, поэтому индексы по полю-ссылке на время практически не влияют (≈1.8 с без условия, ≈1.2 с с условием);
- **в.22**: btree-индекс по `ПРОДАЖА.магазин` даёт лучшее время — **344 мс** против 467 мс без индекса;
- без PRIMARY KEY справочника растёт оценка стоимости (cost): планировщик не знает об уникальности ключа;
- hash-индекс по полю с 5–10 различными значениями строится несколько минут на 2 млн строк (длинные цепочки переполнения) — для таких полей он непригоден.

## 🛡️ Защита ЛР2 (`def_*.sql`)

| | Вариант 20 | Вариант 22 |
|---|---|---|
| Запрос 1) | суммарная выручка двух поставщиков с заданными именами | суммарная выручка от продажи товаров категории |
| Задание 2 | без индексов в `ПРОДАЖА`, `ТОВАР`, `ПОСТАВЩИК`: показ «индексов 0» и проверка плана — индексы не используются; 5 замеров, минимум | только `ПРОДАЖА(товар)` btree, 5 замеров, минимум |
| Задание 3 | `ПРОДАЖА(товар)` btree, `ТОВАР(код, поставщик)` hash, `ПОСТАВЩИК(название)` btree | `ПРОДАЖА(товар)` btree, `ТОВАР(код, категория)` hash, `КАТЕГОРИЯ(наименование)` hash |
| Последний прогон | задание 2 — 482 мс, задание 3 — 480 мс, EXPLAIN ANALYZE — 613 мс | задание 2 — 537 мс, задание 3 — 539 мс, EXPLAIN ANALYZE — 673 мс |

```powershell
./help lr2 def 20                                   # задания 1-3 подряд (по умолч. "ООО Турман" "ЧП Загорье")
./help lr2 def 22 all мебель
./help lr2 def 20 2 "ООО Турман" "ЧП Загорье"       # одно задание: 1, 2 или 3;   ./help lr2 def 22 3 мебель
./help lr2 def 20 idx                               # индексы таблиц запроса;    ./help lr2 def 22 idx_drop|idx_add
./help lr2 def restore                              # после защиты: вернуть PRIMARY KEY
```

Варианты независимы: индексы задания 3 называются `def20_*` и `def22_*`, и любая команда варианта сама удаляет индексы другого варианта ([`def_config.sql`](def_config.sql)) — таблицы `ПРОДАЖА` и `ТОВАР` общие. Индексы планировщик не использует: условие отбирает 40–50 % строк `ПРОДАЖА`, поэтому Parallel Seq Scan + Hash Join дешевле; это показывает проверка плана [`def_plan_check.sql`](def_plan_check.sql).

| Файл | Назначение |
|---|---|
| [`def_z_all.sql`](def_z_all.sql), [`def_z1_query.sql`](def_z1_query.sql), [`def_z2_noidx.sql`](def_z2_noidx.sql), [`def_z3_idx.sql`](def_z3_idx.sql) | задания 1–3 и итоговое сравнение |
| [`def_config.sql`](def_config.sql), [`def_check_args.sql`](def_check_args.sql) | параметры варианта и их проверка, удаление индексов другого варианта |
| [`def_v20_query.sql`](def_v20_query.sql), [`def_v22_query.sql`](def_v22_query.sql) | запрос 1) с подставленными параметрами |
| [`def_time_run.sql`](def_time_run.sql), [`def_time_table.sql`](def_time_table.sql), [`def_plan_check.sql`](def_plan_check.sql) | замер, таблица замеров с минимумом, узлы плана и индексы |
| [`def_drop_all.sql`](def_drop_all.sql), [`def_idx_add.sql`](def_idx_add.sql), [`def_idx_drop.sql`](def_idx_drop.sql), [`def_show_idx.sql`](def_show_idx.sql), [`def_indexes.sql`](def_indexes.sql), [`def_restore.sql`](def_restore.sql) | работа с индексами и восстановление PRIMARY KEY |
| [`def_show_query.sql`](def_show_query.sql) | вывод текста запроса и файла, где он лежит |

Протоколы: [`../results/zas_v20_protocol.txt`](../results/zas_v20_protocol.txt), [`../results/zas_v22_protocol.txt`](../results/zas_v22_protocol.txt), [`../results/zas_restore_protocol.txt`](../results/zas_restore_protocol.txt). Отчёты защиты и листинг программы — [`../reports/zashita`](../reports/zashita).
