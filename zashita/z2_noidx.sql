-- Защита ЛР2, задание 2: таблицы запроса БЕЗ индексов (никаких, в т.ч. PRIMARY KEY),
-- 5 выполнений запроса с фиксацией времени в мс и в минутах, выделение минимального
-- Запуск: ./help zas 20 2 [параметры]   ./help zas 22 2 [параметры]
\set QUIET on
\ir config.sql
\echo '=== Вариант' :variant ', задание 2: удаление всех индексов таблиц' :tbls '==='
\ir drop_all.sql
\set QUIET off
\echo '--- индексы после удаления (пустой список - индексов нет) ---'
\ir indexes.sql
\set QUIET on
CREATE TEMP TABLE zas_время (№ serial, ms numeric);
\set QUIET off
\echo '--- 5 выполнений запроса без индексов (\\timing on: время psql в мс и мин:сек) ---'
\timing on
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\timing off
\echo '--- время 5 выполнений по clock_timestamp() ---'
\ir time_table.sql
