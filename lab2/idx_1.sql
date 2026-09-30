-- ЛР2, этап 3: индекс в ПРОДАЖА по полю-ссылке на таблицу-справочник варианта (аналог idx_1)
-- arg1 - вариант (20|22), arg2 - тип индекса (btree|hash, по умолчанию btree)
-- Запуск: ./h lr2 idx1 20 hash      s.bat lab2\idx_1.sql 20 hash
\set ON_ERROR_STOP on
\set QUIET on
\ir config.sql
\if :{?arg2} \else \set arg2 '' \endif
SELECT CASE WHEN :'arg2' IN ('btree', 'hash') THEN :'arg2' ELSE 'btree' END AS idx_type \gset
\echo 'Индекс' :idx_name 'типа' :idx_type 'по полю ПРОДАЖА.':ref_fk
\set QUIET off
\timing on
DROP INDEX IF EXISTS :"idx_name";
CREATE INDEX :"idx_name" ON ПРОДАЖА USING :idx_type (:"ref_fk");
\timing off
SELECT pg_size_pretty(pg_relation_size(:'idx_name')) AS "размер индекса",
       pg_size_pretty(pg_total_relation_size('ПРОДАЖА')) AS "ПРОДАЖА с индексами";
\ir idx_names.sql
