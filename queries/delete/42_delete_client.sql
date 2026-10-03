-- Удалить клиента вместе с его продажами (аналог TAXI 42: удалить водителя)
-- arg1 - код клиента
-- Запуск: ./help 42 23
BEGIN;
DELETE FROM ПРОДАЖА WHERE клиент = :'arg1'::int;
DELETE FROM КЛИЕНТ WHERE код = :'arg1'::int;
COMMIT;
\echo 'Клиент удалён'
