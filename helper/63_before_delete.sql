-- Состояние ДО DELETE (аналог TAXI)
-- Запуск: ./help 63
\echo '=== СОСТОЯНИЕ ДО DELETE ==='
SELECT 'КЛИЕНТ (код=23)' AS Объект,
       coalesce((SELECT фамилия || ' ' || имя FROM КЛИЕНТ WHERE код = 23), 'удалён') AS Значение
UNION ALL
SELECT 'Продажи клиента 23', count(*)::text FROM ПРОДАЖА WHERE клиент = 23;
