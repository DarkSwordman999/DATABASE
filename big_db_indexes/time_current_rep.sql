-- Повтор замера time_current_run.sql: :runs раз, счётчик :run_no
-- (в psql нет циклов - сценарий подключает сам себя, пока run_no < runs)
SELECT :run_no < :runs AS run_more \gset
\if :run_more
\ir time_current_run.sql
SELECT :run_no + 1 AS run_no \gset
\ir time_current_rep.sql
\endif
