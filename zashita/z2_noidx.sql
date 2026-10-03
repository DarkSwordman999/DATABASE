-- Защита ЛР2, задание 2:
--   в.20 - таблицы запроса БЕЗ индексов (никаких, в т.ч. PRIMARY KEY);
--   в.22 - удаляются все индексы и создаётся один индекс ПРОДАЖА(товар) btree;
-- 5 выполнений запроса с фиксацией времени в мс и в минутах, выделение минимального
-- Запуск: ./help zas 20 2 ["поставщик1" "поставщик2"]   ./help zas 22 2 [категория]
-- Пример: ./help zas 20 2 "ООО Турман" "ЧП Загорье"     ./help zas 22 2 мебель
\set QUIET on
\ir config.sql
\echo '=== Вариант' :variant', задание 2: удаление всех индексов таблиц' :tbls '==='
\ir drop_all.sql
\set QUIET off
\if :is_v20
\echo '--- индексы после удаления (пустой список - индексов нет) ---'
\ir indexes.sql
\set title 'без индексов'
\else
\echo '--- создание индекса ПРОДАЖА по полю товар (btree) ---'
\timing on
CREATE INDEX zas_продажа_товар ON ПРОДАЖА USING btree (товар);
\timing off
\set QUIET on
ANALYZE ПРОДАЖА;
\set QUIET off
\echo '--- индексы таблиц запроса (только zas_продажа_товар) ---'
\ir indexes.sql
\set title 'с индексом ПРОДАЖА(товар) btree'
\endif
\set QUIET on
DROP TABLE IF EXISTS zas_время;
CREATE TEMP TABLE zas_время (№ serial, ms numeric);
\set QUIET off
\echo '--- 5 выполнений запроса' :title '(\\timing on: время psql в мс и мин:сек) ---'
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\echo '--- время 5 выполнений по clock_timestamp() ---'
\ir time_table.sql
