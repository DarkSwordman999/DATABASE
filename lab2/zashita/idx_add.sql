-- Защита ЛР2: создание индексов задания 3 (zas_*) без замеров и EXPLAIN ANALYZE
--   в.20: ПРОДАЖА(товар) btree, ТОВАР(код) hash, ТОВАР(поставщик) hash, ПОСТАВЩИК(название) btree
--   в.22: ПРОДАЖА(товар) btree, ТОВАР(код) hash, ТОВАР(категория) hash, КАТЕГОРИЯ(наименование) hash
-- Уже существующие индексы zas_* не пересоздаются (IF NOT EXISTS)
-- Запуск: ./help zas 20|22 idx_add
-- Пример: ./help zas 20 idx_add      ./help zas 22 idx_add
\set QUIET on
\ir config.sql
\set QUIET off
\echo 'Вариант' :variant': создание индексов задания 3 (zas_*) на таблицах' :tbls
\set ECHO queries
CREATE INDEX IF NOT EXISTS zas_продажа_товар ON ПРОДАЖА USING btree (товар);
CREATE INDEX IF NOT EXISTS zas_товар_код ON ТОВАР USING hash (код);
\if :is_v20
CREATE INDEX IF NOT EXISTS zas_товар_поставщик ON ТОВАР USING hash (поставщик);
CREATE INDEX IF NOT EXISTS zas_поставщик_название ON ПОСТАВЩИК USING btree (название);
\else
CREATE INDEX IF NOT EXISTS zas_товар_категория ON ТОВАР USING hash (категория);
CREATE INDEX IF NOT EXISTS zas_категория_наименование ON КАТЕГОРИЯ USING hash (наименование);
\endif
\set ECHO none
\set QUIET on
ANALYZE ПРОДАЖА;
ANALYZE ТОВАР;
\if :is_v20
ANALYZE ПОСТАВЩИК;
\else
ANALYZE КАТЕГОРИЯ;
\endif
\set QUIET off
\ir indexes.sql
