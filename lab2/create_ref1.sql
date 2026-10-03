-- ЛР2, этап 3: таблица-справочник варианта БЕЗ ключевого поля (нет PRIMARY KEY => нет индекса)
-- Аналог create_товар1. После пересоздания таблица заново заполняется (copy_ref.sql).
-- Запуск: ./help lr2 pk0 20|22      s.bat lab2\create_ref1.sql 20
-- Пример: ./help lr2 pk0 22
\set ON_ERROR_STOP on
\set QUIET on
\ir config.sql
DROP TABLE IF EXISTS :"ref_table";
\if :is_v20
CREATE TABLE ТОВАР (
  код		int,			-- код товара (нет PRIMARY KEY, нет индекса)
  наименование	varchar(20) NULL,	-- наименование/название
  цена1		decimal(12,4) NULL,	-- (оптовая) цена приобретения [ден.ед.]
  цена2		decimal(12,4) NULL,	-- (розничная) цена реализации [ден.ед.]
  категория	int NULL,		-- код из КАТЕГОРИЯ
  поставщик	int NULL,		-- код из ПОСТАВЩИК
  хранение	decimal(12,4) NULL	-- стоимость хранения за 1 день 1 ед. товара [ден.ед.]
);
\else
CREATE TABLE МАГАЗИН (
  код		int NOT NULL,		-- код магазина (нет PRIMARY KEY, нет индекса)
  название	varchar(20) NULL	-- название магазина
);
\endif
\ir copy_ref.sql
\ir idx_names.sql
