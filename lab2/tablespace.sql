-- ЛР2: вынос объёмной таблицы ПРОДАЖА на отдельный диск (табличное пространство)
-- Нужен, если на диске с каталогом данных сервера мало места.
-- Запуск: ./h lr2 tbs [каталог]   (по умолчанию D:/PG_TBS)
-- Каталог должен существовать, а служба PostgreSQL (NETWORK SERVICE) должна иметь права на запись:
--   icacls D:\PG_TBS /grant "*S-1-5-20:(OI)(CI)F"
\set ON_ERROR_STOP on
\if :{?arg1} \else \set arg1 '' \endif
SELECT CASE WHEN :'arg1' > '' THEN :'arg1' ELSE 'D:/PG_TBS' END AS tbs_dir \gset

SELECT NOT EXISTS (SELECT 1 FROM pg_tablespace WHERE spcname = 'lr2_tbs') AS need_tbs \gset
\if :need_tbs
    CREATE TABLESPACE lr2_tbs LOCATION :'tbs_dir';
\endif

-- новые таблицы, индексы и временные файлы запросов - в lr2_tbs
ALTER DATABASE sales SET default_tablespace = 'lr2_tbs';
ALTER DATABASE sales SET temp_tablespaces = 'lr2_tbs';

-- UNLOGGED: изменения ПРОДАЖА не пишутся в журнал WAL (он остаётся на системном диске)
ALTER TABLE ПРОДАЖА SET TABLESPACE lr2_tbs;
ALTER TABLE ПРОДАЖА SET UNLOGGED;

SELECT spcname AS "табличное пространство", pg_tablespace_location(oid) AS "каталог"
  FROM pg_tablespace WHERE spcname = 'lr2_tbs';
SELECT relname AS "таблица",
       CASE relpersistence WHEN 'u' THEN 'UNLOGGED' ELSE 'LOGGED' END AS "журналирование",
       coalesce((SELECT spcname FROM pg_tablespace WHERE oid = reltablespace), 'pg_default') AS "табл. пространство"
  FROM pg_class WHERE relname = 'ПРОДАЖА';
