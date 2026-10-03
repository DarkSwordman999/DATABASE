-- Вызов функции задачи 1: магазины с выручкой выше порога (аналог TAXI 201)
-- arg1 - порог (по умолчанию 100000)
-- Запуск: ./help 201 [порог]
\set QUIET on
\ir 01_create_function_task1.sql
\set QUIET off
SELECT CASE WHEN :'arg1' ~ '^[0-9.]+$' THEN :'arg1' ELSE '100000' END AS порог \gset
\echo 'Функция shops_above_revenue(':порог') определена в queries/functions/01_create_function_task1.sql'
SELECT * FROM shops_above_revenue(:порог);
