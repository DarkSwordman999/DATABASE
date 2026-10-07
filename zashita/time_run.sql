-- Один замер запроса варианта: clock_timestamp() до и после выполнения,
-- время в мс записывается в zas_время. Результат запроса отбрасывается (\o NUL).
-- Вызывается из z2_noidx.sql и z3_idx.sql.
\set QUIET on
SELECT clock_timestamp() AS t1 \gset
\o NUL
:q ;
\o
INSERT INTO zas_время (ms)
SELECT round(EXTRACT(EPOCH FROM clock_timestamp() - :'t1'::timestamptz) * 1000, 3);
