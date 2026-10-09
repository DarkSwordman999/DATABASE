-- Вызов функции задачи 2: выручка по категориям и временам года (аналог TAXI 202)
-- Запуск: ./help 202
\set QUIET on
\ir 02_create_function_task2.sql
\set QUIET off
\echo 'Функция revenue_by_category_and_season() определена в queries/functions/02_create_function_task2.sql'
SELECT категория, время_года AS "время года", продаж, round(выручка, 2) AS выручка
FROM revenue_by_category_and_season();
