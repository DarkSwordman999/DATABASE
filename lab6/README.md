# 🔄 lab6 — ЛР6: копирование базы из PostgreSQL в MS SQL Server

ЛР6 «Копирование базы данных из PostgreSQL в MS SQL Server»: таблицы базы [SALES](../DATA) выгружаются `pg_dump`, структура переводится в T-SQL фильтром `sel2.exe`, данные загружаются `BULK INSERT`; задания [ЛР1](../tasks) переписаны на T-SQL. Папка также содержит общие для ЛР6–ЛР8 настройки подключения к MS SQL Server.

[← к общему описанию проекта](../README.md)

## Файлы

| Файл / папка | Назначение |
|---|---|
| [`config.bat`](config.bat) | подключение к MS SQL Server (по умолчанию LocalDB с Windows-аутентификацией; для сервера в сети — `-S адрес\SQLEXPRESS,1433 -U ... -P ...`), используется в ЛР6 и ЛР7 |
| [`s.bat`](s.bat) | сценарий T-SQL с параметрами `arg1`…`arg5` (sqlcmd, база SALES) |
| [`s_TCP.bat`](s_TCP.bat), [`s0.bat`](s0.bat) | сценарий T-SQL по TCP / консоль sqlcmd |
| [`SETUP/`](SETUP) | проверка сервера: база NEW1, таблица temp1 |
| [`COPY/`](COPY) | перенос базы: `create_DB` (база SALES, сортировка `Cyrillic_General_CI_AS`), `pg_dump_data.bat` / `pg_dump_str.bat` (данные и структура таблицы), `sel2.cpp` и `make_sel2.bat` (фильтр структуры в T-SQL), `BULK_` (шаблон загрузки, `CODEPAGE = '1251'`), `copy_to_MS_SQL.bat` (все таблицы), `disp.bat` (проверка), `select_` (шаблон выборки) |
| [`tasks/`](tasks) | задания ЛР1 вариантов 20 и 22 на T-SQL |
| [`check_db.sql`](check_db.sql) | проверка параметров команд ЛР6–ЛР8 по данным в MS SQL Server (категория, поставщик, товар, сотрудник …) |

Выгрузки `cr_*.txt`, `d_*.txt` и собранный `sel2.exe` в git не хранятся.

## Запуск

```powershell
./help lr6 setup               # проверка сервера
./help lr6 sel2                # собрать sel2.exe
./help lr6 createdb            # база SALES в MS SQL Server
./help lr6 copy                # скопировать все таблицы
./help lr6 disp                # проверить скопированные таблицы
./help lr6 v20 1               # задания на T-SQL (параметры - как ./help v20|v22)
./help lr6 v22 1 01.07.2019 30.06.2023 "ООО Турман"
./help lr6 v22 2 2018 2022 зима
./help lr6 console             # консоль sqlcmd
```

Из `cmd`: `lab6\s.bat lab6\tasks\v20_task1.sql 21.08.2020 20.08.2023 мебель`. sqlcmd не принимает пустые значения `-v`, поэтому `s.bat` добавляет к параметрам префикс `#`, который сценарий отбрасывает.

## Результаты

Все 10 таблиц скопированы с тем же числом строк (`ПРОДАЖА` — 1000, `ПОСТАВКА` — 352, …); результаты всех четырёх заданий на T-SQL совпадают с PostgreSQL — [`../results/lr6_results.txt`](../results/lr6_results.txt). База SALES из этой работы используется в [ЛР7](../lab7) и [ЛР8](../lab8).
