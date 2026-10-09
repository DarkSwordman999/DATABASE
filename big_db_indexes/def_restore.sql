-- Возврат исходного состояния после защиты: индексы удаляются,
-- первичные ключи ТОВАР, ПОСТАВЩИК, КАТЕГОРИЯ восстанавливаются (как в DATA/create_tables)
-- Запуск: ./help lr2 def restore
\set tbls '{ПРОДАЖА,ТОВАР,ПОСТАВЩИК,КАТЕГОРИЯ}'
\set QUIET on
\ir def_drop_all.sql
ALTER TABLE ТОВАР     ADD CONSTRAINT "ТОВАР_pkey"     PRIMARY KEY (код);
ALTER TABLE ПОСТАВЩИК ADD CONSTRAINT "ПОСТАВЩИК_pkey" PRIMARY KEY (код);
ALTER TABLE КАТЕГОРИЯ ADD CONSTRAINT "КАТЕГОРИЯ_pkey" PRIMARY KEY (код);
\set QUIET off
\echo 'Исходные индексы (PRIMARY KEY) восстановлены'
\ir def_indexes.sql
