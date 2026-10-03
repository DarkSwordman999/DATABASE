-- Защита ЛР2, задание 3: индексы варианта, выполнение запроса с фиксацией времени
-- (в.20 - один раз, в.22 - 5 раз и минимальное время) и один раз EXPLAIN ANALYZE
--   в.20: ПРОДАЖА(товар) btree, ТОВАР(код) hash, ТОВАР(поставщик) hash, ПОСТАВЩИК(название) btree
--   в.22: ПРОДАЖА(товар) btree, ТОВАР(код) hash, ТОВАР(категория) hash, КАТЕГОРИЯ(наименование) hash
-- Запуск: ./help zas 20 3 [параметры]   ./help zas 22 3 [параметры]
\set QUIET on
\ir config.sql
\ir drop_all.sql
\set QUIET off
\echo '=== Вариант' :variant ', задание 3: создание индексов ==='
\timing on
CREATE INDEX zas_продажа_товар ON ПРОДАЖА USING btree (товар);
CREATE INDEX zas_товар_код ON ТОВАР USING hash (код);
\if :is_v20
CREATE INDEX zas_товар_поставщик ON ТОВАР USING hash (поставщик);
CREATE INDEX zas_поставщик_название ON ПОСТАВЩИК USING btree (название);
\else
CREATE INDEX zas_товар_категория ON ТОВАР USING hash (категория);
CREATE INDEX zas_категория_наименование ON КАТЕГОРИЯ USING hash (наименование);
\endif
\timing off
\set QUIET on
ANALYZE ПРОДАЖА;
ANALYZE ТОВАР;
\if :is_v20
ANALYZE ПОСТАВЩИК;
\else
ANALYZE КАТЕГОРИЯ;
\endif
\set QUIET off
\ir indexes.sql
\set QUIET on
CREATE TEMP TABLE zas_время (№ serial, ms numeric);
\set QUIET off
\if :is_v20
\echo '--- выполнение запроса с индексами: 1 раз (\\timing on и clock_timestamp()) ---'
\timing on
\ir time_run.sql
\timing off
\else
\echo '--- 5 выполнений запроса с индексами (\\timing on и clock_timestamp()) ---'
\timing on
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\timing off
\endif
\ir time_table.sql
\echo '--- EXPLAIN ANALYZE (один раз) ---'
\set explain 'EXPLAIN ANALYZE'
\ir :query_file
\set explain ''
