-- Восстановление исходных 1000 записей ПРОДАЖА (данные ЛР1)
-- Запуск: ./h lr2 restore
\set ON_ERROR_STOP on
SET datestyle TO 'ISO, DMY';
TRUNCATE ПРОДАЖА;
\copy ПРОДАЖА FROM 'DATA/SOURCE/sales' DELIMITER E'\t' ENCODING 'UTF8'
ANALYZE ПРОДАЖА;
SELECT count(*) AS "строк ПРОДАЖА" FROM ПРОДАЖА;
