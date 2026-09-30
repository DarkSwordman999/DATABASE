-- ЛР2, этап 3: удаление индекса ПРОДАЖА по полю-ссылке на таблицу-справочник (аналог idx_0)
-- Запуск: ./h lr2 idx0 20|22      s.bat lab2\idx_0.sql 20
\set ON_ERROR_STOP on
\set QUIET on
\ir config.sql
\set QUIET off
DROP INDEX IF EXISTS :"idx_name";
SELECT pg_size_pretty(pg_total_relation_size('ПРОДАЖА')) AS "ПРОДАЖА с индексами";
\ir idx_names.sql
