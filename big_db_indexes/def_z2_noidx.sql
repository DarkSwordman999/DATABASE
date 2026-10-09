-- Защита ЛР2, задание 2:
--   в.20 - таблицы запроса БЕЗ индексов (никаких, в т.ч. PRIMARY KEY): показывается, что
--          индексов нет, и по плану запроса - что индексы не используются;
--   в.22 - удаляются все индексы и создаётся один индекс ПРОДАЖА(товар) btree;
-- 5 выполнений запроса, таблица времени в мс, выделено минимальное; EXPLAIN ANALYZE того же
-- запроса и проверка плана (def_plan_check.sql)
-- Запуск: ./help lr2 def 20 2 ["поставщик1" "поставщик2"]   ./help lr2 def 22 2 [категория]
-- Пример: ./help lr2 def 20 2 "ООО Турман" "ЧП Загорье"     ./help lr2 def 22 2 мебель
\set QUIET on
\ir def_config.sql
\ir def_drop_all.sql
\if :is_v20
\set cond2 'без индексов'
\else
\set cond2 'с индексом ПРОДАЖА(товар) btree'
CREATE INDEX def22_продажа_товар ON ПРОДАЖА USING btree (товар);
ANALYZE ПРОДАЖА;
\endif
DROP TABLE IF EXISTS def_время;
CREATE TEMP TABLE def_время (№ serial, ms numeric);
\echo '=============================================================================='
\echo 'ВАРИАНТ' :variant'. ЗАДАНИЕ 2. Время выполнения запроса 1) - 5 замеров'
\echo '=============================================================================='
\echo 'Индексы таблиц' :tbls '(по системному каталогу pg_index):'
SELECT t.relname AS "таблица",
       count(i.indexrelid) AS "индексов",
       coalesce(string_agg(ic.relname, ', ' ORDER BY ic.relname), '-') AS "индексы"
  FROM unnest(:'tbls'::text[]) AS t(relname)
       LEFT JOIN pg_class tc ON tc.relname = t.relname AND tc.relkind = 'r'
       LEFT JOIN pg_index i  ON i.indrelid = tc.oid
       LEFT JOIN pg_class ic ON ic.oid = i.indexrelid
 GROUP BY t.relname
 ORDER BY 1;
\if :is_v20
SELECT count(*) = 0 AS no_idx
  FROM pg_index i JOIN pg_class t ON t.oid = i.indrelid
 WHERE t.relname = ANY (:'tbls'::text[]) \gset
\if :no_idx
\echo 'Индексов на таблицах запроса нет (удалены и индексы PRIMARY KEY).'
\else
\echo 'ВНИМАНИЕ: на таблицах запроса остались индексы.'
\endif
\endif
\echo
\ir def_show_query.sql
\ir def_time_run.sql
\ir def_time_run.sql
\ir def_time_run.sql
\ir def_time_run.sql
\ir def_time_run.sql
\set t2 'Время 5 выполнений запроса (' :cond2 '):'
\echo :t2
\ir def_time_table.sql
\set min2 :min_ms
\echo
\set t2 'EXPLAIN ANALYZE того же запроса (' :cond2 '):'
\echo :t2
\ir def_show_query.sql
EXPLAIN ANALYZE :q ;
\ir def_plan_check.sql
