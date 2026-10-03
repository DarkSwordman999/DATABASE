-- Создание всех функций (аналог TAXI 200)
-- Запуск: ./help 200
\ir 01_create_function_task1.sql
\echo 'shops_above_revenue(порог)        - queries/functions/01_create_function_task1.sql'
\ir 02_create_function_task2.sql
\echo 'revenue_by_category_and_season() - queries/functions/02_create_function_task2.sql'
\ir 03_create_function_task3.sql
\echo 'display_pivot_table()            - queries/functions/03_create_function_task3.sql'
\echo 'Все функции созданы'
SELECT p.proname AS функция, pg_get_function_arguments(p.oid) AS аргументы,
       pg_get_function_result(p.oid) AS результат
FROM pg_proc p
WHERE p.proname IN ('shops_above_revenue', 'revenue_by_category_and_season', 'display_pivot_table')
ORDER BY p.proname;
