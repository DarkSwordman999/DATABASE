-- Защита ЛР2, задание 2:
--   в.20 - таблицы запроса БЕЗ индексов (никаких, в т.ч. PRIMARY KEY);
--   в.22 - удаляются все индексы и создаётся один индекс ПРОДАЖА(товар) btree;
-- 5 выполнений запроса, таблица времени в мс и в минутах, выделено минимальное
-- Запуск: ./help zas 20 2 ["поставщик1" "поставщик2"]   ./help zas 22 2 [категория]
-- Пример: ./help zas 20 2 "ООО Турман" "ЧП Загорье"     ./help zas 22 2 мебель
\set QUIET on
\ir config.sql
\ir drop_all.sql
\if :is_v20
\else
CREATE INDEX zas_продажа_товар ON ПРОДАЖА USING btree (товар);
ANALYZE ПРОДАЖА;
\endif
DROP TABLE IF EXISTS zas_время;
CREATE TEMP TABLE zas_время (№ serial, ms numeric);
-- индексы таблиц запроса одной строкой: «нет» или список «индекс (метод)»
SELECT coalesce(string_agg(ic.relname || ' (' || am.amname || ')', ', ' ORDER BY ic.relname),
                'нет') AS idx_list
  FROM pg_index i
       JOIN pg_class t  ON t.oid = i.indrelid
       JOIN pg_class ic ON ic.oid = i.indexrelid
       JOIN pg_am am    ON am.oid = ic.relam
 WHERE t.relname = ANY (:'tbls'::text[]) \gset
\echo '=============================================================================='
\echo 'ВАРИАНТ' :variant'. ЗАДАНИЕ 2. Время выполнения запроса 1) - 5 замеров'
\echo '=============================================================================='
\echo 'Индексы таблиц' :tbls':' :idx_list
\echo
\ir show_query.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\ir time_run.sql
\echo 'Время 5 выполнений запроса:'
\ir time_table.sql
\set min2 :min_ms
