-- ВЫПОЛНЕНИЕ UPDATE (вернуть исходные значения: ./help 66)
-- Запуск: ./help 61
\echo '=== ВЫПОЛНЯЕМ UPDATE ==='
UPDATE ТОВАР SET цена2 = 399.99 WHERE код = 1;
UPDATE СОТРУДНИК SET имя = 'Николай (ст.)' WHERE код = 1;
\echo 'UPDATE ВЫПОЛНЕН'
