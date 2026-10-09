-- Защита ЛР2: создание индексов задания 3 своего варианта (def20_* / def22_*) без замеров
-- и EXPLAIN ANALYZE; индексы другого варианта удаляются в config.sql
--   в.20: ПРОДАЖА(товар) btree, ТОВАР(код) hash, ТОВАР(поставщик) hash, ПОСТАВЩИК(название) btree
--   в.22: ПРОДАЖА(товар) btree, ТОВАР(код) hash, ТОВАР(категория) hash, КАТЕГОРИЯ(наименование) hash
-- Уже существующие индексы не пересоздаются (IF NOT EXISTS)
-- Запуск: ./help lr2 def 20|22 idx_add
-- Пример: ./help lr2 def 20 idx_add      ./help lr2 def 22 idx_add
\set QUIET on
\ir config.sql
\set QUIET off
\echo 'Вариант' :variant': создание индексов задания 3 на таблицах' :tbls
\set ECHO queries
\if :is_v20
CREATE INDEX IF NOT EXISTS def20_продажа_товар ON ПРОДАЖА USING btree (товар);
CREATE INDEX IF NOT EXISTS def20_товар_код ON ТОВАР USING hash (код);
CREATE INDEX IF NOT EXISTS def20_товар_поставщик ON ТОВАР USING hash (поставщик);
CREATE INDEX IF NOT EXISTS def20_поставщик_название ON ПОСТАВЩИК USING btree (название);
\else
CREATE INDEX IF NOT EXISTS def22_продажа_товар ON ПРОДАЖА USING btree (товар);
CREATE INDEX IF NOT EXISTS def22_товар_код ON ТОВАР USING hash (код);
CREATE INDEX IF NOT EXISTS def22_товар_категория ON ТОВАР USING hash (категория);
CREATE INDEX IF NOT EXISTS def22_категория_наименование ON КАТЕГОРИЯ USING hash (наименование);
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
