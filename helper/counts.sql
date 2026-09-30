-- Контроль количества строк в таблицах базы SALES
SELECT 'РАЙОН' AS "таблица", count(*) AS "строк" FROM РАЙОН
UNION ALL SELECT 'КАТЕГОРИЯ', count(*) FROM КАТЕГОРИЯ
UNION ALL SELECT 'ПОСТАВЩИК', count(*) FROM ПОСТАВЩИК
UNION ALL SELECT 'ТОВАР',     count(*) FROM ТОВАР
UNION ALL SELECT 'МАГАЗИН',   count(*) FROM МАГАЗИН
UNION ALL SELECT 'СОТРУДНИК', count(*) FROM СОТРУДНИК
UNION ALL SELECT 'КЛИЕНТ',    count(*) FROM КЛИЕНТ
UNION ALL SELECT 'РАБОТА',    count(*) FROM РАБОТА
UNION ALL SELECT 'ПОСТАВКА',  count(*) FROM ПОСТАВКА
UNION ALL SELECT 'ПРОДАЖА',   count(*) FROM ПРОДАЖА;
