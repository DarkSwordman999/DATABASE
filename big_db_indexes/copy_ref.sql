-- ЛР2, этап 3: загрузка таблицы-справочника варианта из DATA/SOURCE (аналог COPY_товар)
-- (\copy не подставляет переменные psql, поэтому команда выбирается по варианту)
-- Запуск (из корня проекта): ./help lr2 copy 20|22      s.bat big_db_indexes\copy_ref.sql 20
-- Пример: ./help lr2 copy 22
\set ON_ERROR_STOP on
\set QUIET on
\ir config.sql
DELETE FROM :"ref_table";
\if :is_v20
\copy ТОВАР FROM 'DATA/SOURCE/goods' DELIMITER E'\t' ENCODING 'UTF8'
\else
\copy МАГАЗИН FROM 'DATA/SOURCE/shops' DELIMITER E'\t' ENCODING 'UTF8'
\endif
\set QUIET off
SELECT * FROM :"ref_table" ORDER BY код;
