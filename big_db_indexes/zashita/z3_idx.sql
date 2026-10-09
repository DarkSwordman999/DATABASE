-- Защита ЛР2, задание 3: ввод индексов варианта, выполнение запроса с фиксацией времени
-- (5 раз и минимальное время), EXPLAIN ANALYZE того же запроса и проверка плана (plan_check.sql);
-- индексы называются def20_* / def22_* и остаются до запуска команды другого варианта
--   в.20: ПРОДАЖА(товар) btree, ТОВАР(код) hash, ТОВАР(поставщик) hash, ПОСТАВЩИК(название) btree
--   в.22: ПРОДАЖА(товар) btree, ТОВАР(код) hash, ТОВАР(категория) hash, КАТЕГОРИЯ(наименование) hash
-- Запуск: ./help lr2 def 20 3 [параметры]   ./help lr2 def 22 3 [параметры]
-- Пример: ./help lr2 def 20 3 "ООО Турман" "ЧП Загорье"     ./help lr2 def 22 3 мебель
\set QUIET on
\ir config.sql
\ir drop_all.sql
\echo '=============================================================================='
\echo 'ВАРИАНТ' :variant'. ЗАДАНИЕ 3. Индексы, время выполнения запроса 1), EXPLAIN ANALYZE'
\echo '=============================================================================='
\echo 'Ввод индексов (прежние индексы таблиц' :tbls 'удалены):'
\set ECHO queries
\if :is_v20
CREATE INDEX def20_продажа_товар ON ПРОДАЖА USING btree (товар);
CREATE INDEX def20_товар_код ON ТОВАР USING hash (код);
CREATE INDEX def20_товар_поставщик ON ТОВАР USING hash (поставщик);
CREATE INDEX def20_поставщик_название ON ПОСТАВЩИК USING btree (название);
\else
CREATE INDEX def22_продажа_товар ON ПРОДАЖА USING btree (товар);
CREATE INDEX def22_товар_код ON ТОВАР USING hash (код);
CREATE INDEX def22_товар_категория ON ТОВАР USING hash (категория);
CREATE INDEX def22_категория_наименование ON КАТЕГОРИЯ USING hash (наименование);
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
DROP TABLE IF EXISTS def_время;
CREATE TEMP TABLE def_время (№ serial, ms numeric);
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\echo 'Время 5 выполнений запроса с индексами:'
\ir time_table.sql
\set min3 :min_ms
\echo
\echo 'EXPLAIN ANALYZE того же запроса, что и 5 замеров выше:'
EXPLAIN ANALYZE :q ;
\ir plan_check.sql
