-- ЛР2, этап 2б: время выполнения запроса (*) командой \timing on, 5 повторов
-- (аналог time05b). Время выводится psql после каждого запроса.
-- Запуск: ./help lr2 timing 20|22   s.bat lab2\time_timing.sql 20
-- Пример: ./help lr2 timing 22
\set ON_ERROR_STOP on
\set QUIET on
\ir config.sql
\echo
\echo '=== ЛР2 / Вариант' :variant '/ Этап 2б: psql timing ==='
\echo '--- результат запроса (*) ---'
\ir :query_file
\echo '--- 5 замеров (вывод строк отключён) ---'
\timing on
\o NUL
\ir :query_file
\ir :query_file
\ir :query_file
\ir :query_file
\ir :query_file
\o
\timing off
