-- ЛР2, этап 2а: время выполнения запроса (*) по CURRENT_TIME, 5 повторов
-- Запуск: ./h lr2 time 20|22     s.bat lab2\time_current.sql 20
\set ON_ERROR_STOP on
\set QUIET on
\ir config.sql
\echo
\echo '=== ЛР2 / Вариант' :variant '/ Этап 2а: CURRENT_TIME ==='
\echo 'Запрос (*):' :query_file '  строк в ПРОДАЖА:'
SELECT count(*) AS "строк ПРОДАЖА" FROM ПРОДАЖА;

CREATE TEMP TABLE lr2_время (№ serial, секунды numeric);
\ir time_current_run.sql
\ir time_current_run.sql
\ir time_current_run.sql
\ir time_current_run.sql
\ir time_current_run.sql

SELECT №::text AS "замер", ROUND(секунды, 6) AS "время, с" FROM lr2_время
UNION ALL
SELECT 'среднее', ROUND(avg(секунды), 6) FROM lr2_время;
