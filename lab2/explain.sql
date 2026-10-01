-- ЛР2, этап 4: план и время выполнения запроса к ПРОДАЖА, связанной с таблицей-справочником
-- arg1 - вариант (20|22), arg2 - 1: с условием WHERE на поле справочника, иначе без него
-- Запуск: ./help lr2 explain 20 [1]      s.bat lab2\explain.sql 20 1
\set ON_ERROR_STOP on
\set QUIET on
\ir config.sql
\if :{?arg2} \else \set arg2 '' \endif
SELECT :'arg2' = '1' AS with_where \gset
\if :with_where
    \set q :join_query ' ' :where_cond
\else
    \set q :join_query
\endif
\ir idx_names.sql
\echo
\echo '--- EXPLAIN (оценка стоимости, без выполнения) ---'
\echo :q
\set QUIET off
EXPLAIN :q;
\echo '--- EXPLAIN ANALYZE (фактическое выполнение) ---'
EXPLAIN ANALYZE :q;
