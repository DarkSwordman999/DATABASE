-- Один замер запроса (*) через CURRENT_TIME (аналог time05a)
-- Результат запроса отбрасывается (\o NUL), время пишется в lr2_время
SELECT CURRENT_TIME AS t1 \gset
\o NUL
\ir :query_file
\o
SELECT CURRENT_TIME AS t2 \gset
INSERT INTO lr2_время (секунды)
SELECT EXTRACT(EPOCH FROM (:'t2'::time - :'t1'::time));
