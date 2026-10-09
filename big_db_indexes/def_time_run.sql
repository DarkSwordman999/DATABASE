-- Один замер запроса варианта: clock_timestamp() до и после выполнения,
-- время в мс записывается в def_время. Результат запроса отбрасывается (\o NUL).
-- Вызывается из def_z2_noidx.sql и def_z3_idx.sql.
\set QUIET on
SELECT clock_timestamp() AS t1 \gset
\o NUL
:q ;
\o
INSERT INTO def_время (ms)
SELECT round(EXTRACT(EPOCH FROM clock_timestamp() - :'t1'::timestamptz) * 1000, 3);
