-- Вызов функции задачи 3: сводная таблица магазины x категории (аналог TAXI 203)
-- Запуск: ./help 203
\set QUIET on
\ir 03_create_function_task3.sql
\set QUIET off
\echo 'Функция display_pivot_table() определена в queries/functions/03_create_function_task3.sql'
SELECT магазин, round(мебель, 2) AS мебель, round(одежда, 2) AS одежда, round(итого, 2) AS итого
FROM display_pivot_table();
