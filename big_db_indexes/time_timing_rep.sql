-- Повтор запроса (*) с \timing on: :runs раз, счётчик :run_no
-- (в psql нет циклов - сценарий подключает сам себя, пока run_no < runs;
-- \timing включается только на время запроса, чтобы не выводить время служебных SELECT)
SELECT :run_no < :runs AS run_more \gset
\if :run_more
\timing on
\ir :query_file
\timing off
SELECT :run_no + 1 AS run_no \gset
\ir time_timing_rep.sql
\endif
