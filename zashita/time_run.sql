-- Один замер запроса варианта двумя способами:
--   \timing on - время выполнения запроса по psql (мс и мин:сек), выводится строкой "Время:";
--   clock_timestamp() на сервере до и после запроса - записывается в zas_время.
-- Результат запроса отбрасывается (\o NUL). Вызывается из z2_noidx.sql и z3_idx.sql.
\set QUIET on
SELECT count(*) + 1 AS n FROM zas_время \gset
\echo 'Замер' :n
SELECT clock_timestamp() AS t1 \gset
\timing on
\o NUL
\ir :query_file
\o
\timing off
INSERT INTO zas_время (ms)
SELECT round(EXTRACT(EPOCH FROM clock_timestamp() - :'t1'::timestamptz) * 1000, 3);
\set QUIET off
