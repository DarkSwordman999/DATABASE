-- Вызов функции задачи 3: сводная таблица магазины x категории (аналог TAXI 203)
-- Запуск: ./help 203
\set QUIET on
\ir 03_create_function_task3.sql
\set QUIET off
\echo 'Функция display_pivot_table() определена в queries/functions/03_create_function_task3.sql'
SELECT * FROM display_pivot_table();
