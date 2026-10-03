-- ВЫПОЛНЕНИЕ DELETE: клиент 23 и его продажи (вернуть: ./help 66)
-- Запуск: ./help 64
\echo '=== ВЫПОЛНЯЕМ DELETE ==='
BEGIN;
DELETE FROM ПРОДАЖА WHERE клиент = 23;
DELETE FROM КЛИЕНТ WHERE код = 23;
COMMIT;
\echo 'DELETE ВЫПОЛНЕН'
