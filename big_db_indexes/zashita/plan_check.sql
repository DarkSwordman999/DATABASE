-- Защита ЛР2: проверка плана запроса :q - какие узлы читают таблицы и используют ли они индексы
-- (Index Scan, Index Only Scan, Bitmap Index Scan). План берётся командой EXPLAIN - тот же,
-- что у EXPLAIN ANALYZE, но без повторного выполнения запроса.
-- Вызывается из z2_noidx.sql и z3_idx.sql после EXPLAIN ANALYZE.
\set QUIET on
SELECT set_config('def.q', :'q', false) AS none \gset
CREATE OR REPLACE FUNCTION pg_temp.def_plan_scans()
RETURNS TABLE ("узел плана" text, "индекс" text) AS $$
DECLARE l text;
BEGIN
    FOR l IN EXECUTE 'EXPLAIN ' || current_setting('def.q') LOOP
        IF l ~ ' Scan ' THEN
            "узел плана" := regexp_replace(trim(regexp_replace(l, '^[ ->]*', '')), '\s+\(cost=.*$', '');
            "индекс" := CASE WHEN l ~ '(Index Scan|Index Only Scan|Bitmap Index Scan)'
                             THEN 'используется' ELSE 'нет' END;
            RETURN NEXT;
        END IF;
    END LOOP;
END $$ LANGUAGE plpgsql;
SELECT count(*) FILTER (WHERE "индекс" = 'используется') = 0 AS no_idx_scan
  FROM pg_temp.def_plan_scans() \gset
\echo 'Чтение таблиц в плане запроса (EXPLAIN):'
SELECT * FROM pg_temp.def_plan_scans();
\if :no_idx_scan
\echo 'Итог: индексы в плане НЕ используются - таблицы читаются последовательно (Seq Scan).'
\else
\echo 'Итог: в плане есть узлы, читающие таблицы через индекс (см. столбец «индекс»).'
\endif
\echo
