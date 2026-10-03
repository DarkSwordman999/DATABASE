-- Вызов функции задачи 2: выручка по категориям и временам года (аналог TAXI 202)
-- Запуск: ./help 202
\set QUIET on
\ir 02_create_function_task2.sql
\set QUIET off
\echo 'Функция revenue_by_category_and_season() определена в queries/functions/02_create_function_task2.sql'
SELECT * FROM revenue_by_category_and_season();
