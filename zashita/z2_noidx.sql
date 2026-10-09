-- Защита ЛР2, задание 2:
--   в.20 - таблицы запроса БЕЗ индексов (никаких, в т.ч. PRIMARY KEY);
--   в.22 - удаляются все индексы и создаётся один индекс ПРОДАЖА(товар) btree;
-- 5 выполнений запроса, таблица времени в мс, выделено минимальное; EXPLAIN ANALYZE того же запроса
-- Запуск: ./help zas 20 2 ["поставщик1" "поставщик2"]   ./help zas 22 2 [категория]
-- Пример: ./help zas 20 2 "ООО Турман" "ЧП Загорье"     ./help zas 22 2 мебель
\set QUIET on
\ir config.sql
\ir drop_all.sql
\if :is_v20
\set cond2 'без индексов'
\else
\set cond2 'с индексом ПРОДАЖА(товар) btree'
CREATE INDEX zas_продажа_товар ON ПРОДАЖА USING btree (товар);
ANALYZE ПРОДАЖА;
\endif
DROP TABLE IF EXISTS zas_время;
CREATE TEMP TABLE zas_время (№ serial, ms numeric);
\echo '=============================================================================='
\echo 'ВАРИАНТ' :variant'. ЗАДАНИЕ 2. Время выполнения запроса 1) - 5 замеров'
\echo '=============================================================================='
\echo 'Индексы таблиц' :tbls':'
SELECT t.relname AS "таблица",
       coalesce(ic.relname, '') AS "индекс"
  FROM (SELECT unnest(:'tbls'::text[]) AS relname) t
       LEFT JOIN pg_class tc ON tc.relname = t.relname
       LEFT JOIN pg_index i  ON i.indrelid = tc.oid
       LEFT JOIN pg_class ic ON ic.oid = i.indexrelid
 ORDER BY 1, 2;
\echo
\ir show_query.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\set t2 'Время 5 выполнений запроса (' :cond2 '):'
\echo :t2
\ir time_table.sql
\set min2 :min_ms
\echo
\set t2 'EXPLAIN ANALYZE того же запроса (' :cond2 '):'
\echo :t2
\ir show_query.sql
EXPLAIN ANALYZE :q ;
