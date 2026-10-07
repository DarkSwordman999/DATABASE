-- ЛР2, этап 2б: время выполнения запроса (*) командой \timing on, arg2 повторов (по умолчанию 5)
-- (аналог time05b). Время выводится psql после каждого запроса.
-- Запуск: ./help lr2 timing 20|22 [замеров]   s.bat lab2\time_timing.sql 20 [замеров]
-- Пример: ./help lr2 timing 20 5     ./help lr2 timing 22 10
\set ON_ERROR_STOP on
\set QUIET on
\ir config.sql
\if :{?arg2} \else \set arg2 '' \endif
SELECT CASE WHEN :'arg2' ~ '^[1-9][0-9]*$' THEN :'arg2' ELSE '5' END AS runs \gset
\echo
\echo '=== ЛР2 / Вариант' :variant '/ Этап 2б: psql timing ==='
\echo '--- результат запроса (*) ---'
\ir :query_file
\echo '---' :runs 'замеров (вывод строк отключён) ---'
\set run_no 0
\o NUL
\ir time_timing_rep.sql
\o
