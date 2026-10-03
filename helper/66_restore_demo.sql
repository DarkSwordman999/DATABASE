-- Возврат исходных значений после ./help 61 и ./help 64 (данные из DATA/SOURCE)
-- Продажи клиента 23 возвращаются только для данных ЛР1 (1000 записей ПРОДАЖА);
-- после ./help lr2 gen продажи этого клиента не восстанавливаются (их нет в DATA/SOURCE).
-- Запуск: ./help 66
\set ON_ERROR_STOP on
SET datestyle TO 'ISO, DMY';
UPDATE ТОВАР SET цена2 = 350 WHERE код = 1;
UPDATE СОТРУДНИК SET имя = 'Николай' WHERE код = 1;

CREATE TEMP TABLE клиент_исх (LIKE КЛИЕНТ);
\copy клиент_исх FROM 'DATA/SOURCE/clients' DELIMITER E'\t' ENCODING 'UTF8'
INSERT INTO КЛИЕНТ SELECT * FROM клиент_исх WHERE код = 23 AND код NOT IN (SELECT код FROM КЛИЕНТ);

SELECT count(*) <= 1000 AS lr1_data FROM ПРОДАЖА \gset
\if :lr1_data
CREATE TEMP TABLE продажа_исх (LIKE ПРОДАЖА);
\copy продажа_исх FROM 'DATA/SOURCE/sales' DELIMITER E'\t' ENCODING 'UTF8'
INSERT INTO ПРОДАЖА SELECT * FROM продажа_исх
 WHERE клиент = 23 AND NOT EXISTS (SELECT 1 FROM ПРОДАЖА WHERE клиент = 23);
\endif
\echo '=== ИСХОДНЫЕ ЗНАЧЕНИЯ ВОЗВРАЩЕНЫ ==='
\ir 60_before_update.sql
\ir 63_before_delete.sql
