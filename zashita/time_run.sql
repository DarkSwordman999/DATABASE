-- Один замер запроса варианта: время фиксируется clock_timestamp() на сервере
-- до и после запроса (результат отбрасывается \o NUL) и выводится psql (\timing on)
SELECT clock_timestamp() AS t1 \gset
\o NUL
\ir :query_file
\o
INSERT INTO zas_время (ms)
SELECT round(EXTRACT(EPOCH FROM clock_timestamp() - :'t1'::timestamptz) * 1000, 3);
