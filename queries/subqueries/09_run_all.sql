-- Все задачи с подзапросами и проверка представлений (аналог TAXI 199)
-- Запуск: ./help 199
\echo '=== ПРОВЕРКА ПРЕДСТАВЛЕНИЙ (queries/views/03_check_views.sql) ==='
\ir ../views/03_check_views.sql
\echo '=== 1.1 (01_price_deviation.sql) ==='
\ir 01_price_deviation.sql
\echo '=== 1.2 (02_goods_rating.sql) ==='
\ir 02_goods_rating.sql
\echo '=== 2.1 (03_sales_above_avg.sql) ==='
\ir 03_sales_above_avg.sql
\echo '=== 2.2 (04_category_stats.sql) ==='
\ir 04_category_stats.sql
\echo '=== 3.1 (05_top_goods_lateral.sql) ==='
\ir 05_top_goods_lateral.sql
\set arg1 Воронов
\echo '=== 4.1 (06_sales_above_avg_param.sql) ==='
\ir 06_sales_above_avg_param.sql
\echo '=== 4.2 (07_good_clients_exists.sql) ==='
\ir 07_good_clients_exists.sql
\echo '=== 4.3 (08_best_shops_all.sql) ==='
\ir 08_best_shops_all.sql
