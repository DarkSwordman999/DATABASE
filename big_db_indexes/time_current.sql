-- ЛР2, этап 2а: время выполнения запроса (*) по CURRENT_TIME, arg2 повторов (по умолчанию 5)
-- Запуск: ./help lr2 time 20|22 [замеров]     s.bat big_db_indexes\time_current.sql 20 [замеров]
-- Пример: ./help lr2 time 20 5     ./help lr2 time 22 10
\set ON_ERROR_STOP on
\set QUIET on
\ir config.sql
\if :{?arg2} \else \set arg2 '' \endif
SELECT CASE WHEN :'arg2' ~ '^[1-9][0-9]*$' THEN :'arg2' ELSE '5' END AS runs \gset
\echo
\echo '=== ЛР2 / Вариант' :variant '/ Этап 2а: CURRENT_TIME ==='
\echo 'Запрос (*): файл' :query_path '  замеров:' :runs '  строк в ПРОДАЖА:'
SELECT count(*) AS "строк ПРОДАЖА" FROM ПРОДАЖА;

CREATE TEMP TABLE lr2_время (№ serial, секунды numeric);
\set run_no 0
\ir time_current_rep.sql

SELECT №::text AS "замер", ROUND(секунды, 6) AS "время, с" FROM lr2_время
UNION ALL
SELECT 'среднее', ROUND(avg(секунды), 6) FROM lr2_время;
