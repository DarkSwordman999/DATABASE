# 📊 results — протоколы измерений и результаты прогонов

Протоколы, полученные командами `./help` на реальных серверах (PostgreSQL 18.6, SQL Server 2019 LocalDB). На них ссылаются README работ и отчёты в [`../reports`](../reports).

[← к общему описанию проекта](../README.md)

| Файл | Работа | Как получен |
|---|---|---|
| [`lr2_v20_results.txt`](lr2_v20_results.txt), [`lr2_v22_results.txt`](lr2_v22_results.txt) | [ЛР2](../big_db_indexes) — время запроса при всех сочетаниях индексов и ключей | `./help lr2 measure 20\|22` |
| [`zas_v20_protocol.txt`](zas_v20_protocol.txt), [`zas_v22_protocol.txt`](zas_v22_protocol.txt), [`zas_restore_protocol.txt`](zas_restore_protocol.txt) | [защита ЛР2](../big_db_indexes) — задания 1–3 и возврат PRIMARY KEY | `./help lr2 def 20`, `./help lr2 def 22`, `./help lr2 def restore` |
| [`lr4_v20_protocol.txt`](lr4_v20_protocol.txt), [`lr4_v22_protocol.txt`](lr4_v22_protocol.txt) | [ЛР4](../lab4) — копирование и восстановление, пп. 1–10, сравнение `fc` | `./help lr4 all 20\|22` |
| [`lr4/v20/`](lr4/v20), [`lr4/v22/`](lr4/v22) | ЛР4 — результаты контрольных задач `task0-01..03` до копирования | `./help lr4 tasks 0` |
| [`lr6_results.txt`](lr6_results.txt) | [ЛР6](../lab6) — задания на T-SQL и число строк после переноса | `./help lr6 …` |
| [`lr7_v20_results.txt`](lr7_v20_results.txt), [`lr7_v22_results.txt`](lr7_v22_results.txt) | [ЛР7](../lab7) — премия и затраты на хранение с параметрами варианта | `./help lr7 1\|2 …` |
| [`lr8_v20_results.txt`](lr8_v20_results.txt), [`lr8_v22_results.txt`](lr8_v22_results.txt) | [ЛР8](../lab8) — программы C# и Python | `./help lr8 20\|22 …` |
