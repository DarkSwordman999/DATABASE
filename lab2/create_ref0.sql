-- ЛР2, этап 3: таблица-справочник варианта С ключевым полем (PRIMARY KEY => есть индекс)
-- Аналог create_товар0. После пересоздания таблица заново заполняется (copy_ref.sql).
-- Запуск: ./help lr2 pk1 20|22      s.bat lab2\create_ref0.sql 20
\set ON_ERROR_STOP on
\set QUIET on
\ir config.sql
DROP TABLE IF EXISTS :"ref_table";
\if :is_v20
CREATE TABLE ТОВАР (
  код		int PRIMARY KEY,	-- код товара (есть индекс ТОВАР_pkey)
  наименование	varchar(20) NULL,	-- наименование/название
  цена1		decimal(12,4) NULL,	-- (оптовая) цена приобретения [ден.ед.]
  цена2		decimal(12,4) NULL,	-- (розничная) цена реализации [ден.ед.]
  категория	int NULL,		-- код из КАТЕГОРИЯ
  поставщик	int NULL,		-- код из ПОСТАВЩИК
  хранение	decimal(12,4) NULL	-- стоимость хранения за 1 день 1 ед. товара [ден.ед.]
);
\else
CREATE TABLE МАГАЗИН (
  код		int NOT NULL PRIMARY KEY,	-- код магазина (есть индекс МАГАЗИН_pkey)
  название	varchar(20) NULL		-- название магазина
);
\endif
\ir copy_ref.sql
\ir idx_names.sql
