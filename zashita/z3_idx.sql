-- Защита ЛР2, задание 3: ввод индексов варианта, выполнение запроса с фиксацией времени
-- (в.20 - один раз, в.22 - 5 раз и минимальное время) и один раз EXPLAIN ANALYZE
--   в.20: ПРОДАЖА(товар) btree, ТОВАР(код) hash, ТОВАР(поставщик) hash, ПОСТАВЩИК(название) btree
--   в.22: ПРОДАЖА(товар) btree, ТОВАР(код) hash, ТОВАР(категория) hash, КАТЕГОРИЯ(наименование) hash
-- Запуск: ./help zas 20 3 [параметры]   ./help zas 22 3 [параметры]
-- Пример: ./help zas 20 3 "ООО Турман" "ЧП Загорье"     ./help zas 22 3 мебель
\set QUIET on
\ir config.sql
\ir drop_all.sql
\echo '=============================================================================='
\echo 'ВАРИАНТ' :variant'. ЗАДАНИЕ 3. Индексы, время выполнения запроса 1), EXPLAIN ANALYZE'
\echo '=============================================================================='
\echo 'Ввод индексов (прежние индексы таблиц' :tbls 'удалены):'
\set ECHO queries
CREATE INDEX zas_продажа_товар ON ПРОДАЖА USING btree (товар);
CREATE INDEX zas_товар_код ON ТОВАР USING hash (код);
\if :is_v20
CREATE INDEX zas_товар_поставщик ON ТОВАР USING hash (поставщик);
CREATE INDEX zas_поставщик_название ON ПОСТАВЩИК USING btree (название);
\else
CREATE INDEX zas_товар_категория ON ТОВАР USING hash (категория);
CREATE INDEX zas_категория_наименование ON КАТЕГОРИЯ USING hash (наименование);
\endif
\set ECHO none
ANALYZE ПРОДАЖА;
ANALYZE ТОВАР;
\if :is_v20
ANALYZE ПОСТАВЩИК;
\else
ANALYZE КАТЕГОРИЯ;
\endif
\echo
\echo 'Индексы таблиц запроса после ввода (по системному каталогу pg_index):'
SELECT CASE t.relname WHEN 'ПРОДАЖА' THEN '1)' WHEN 'ТОВАР' THEN '2)' ELSE '3)' END AS "п.",
       t.relname AS "таблица", a.attname AS "поле", am.amname AS "тип", ic.relname AS "индекс"
  FROM pg_index i
       JOIN pg_class t     ON t.oid = i.indrelid
       JOIN pg_class ic    ON ic.oid = i.indexrelid
       JOIN pg_am am       ON am.oid = ic.relam
       JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = i.indkey[0]
 WHERE t.relname = ANY (:'tbls'::text[])
 ORDER BY 1, ic.oid;
\ir show_query.sql
DROP TABLE IF EXISTS zas_время;
CREATE TEMP TABLE zas_время (№ serial, ms numeric);
\if :is_v20
\ir time_run.sql
\echo 'Время выполнения запроса с индексами (1 замер):'
\else
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\echo 'Время 5 выполнений запроса с индексами:'
\endif
\ir time_table.sql
\set min3 :min_ms
\echo
\echo 'EXPLAIN ANALYZE (один раз):'
EXPLAIN ANALYZE :q ;
