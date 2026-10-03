-- Продажи по часам дня (аналог TAXI: поездки по часам)
-- Запуск: ./help 21
SELECT EXTRACT(HOUR FROM ПРОДАЖА.дата)::int AS час, count(*) AS продаж, sum(ПРОДАЖА.количество * ТОВАР.цена2) AS выручка
FROM ПРОДАЖА
INNER JOIN ТОВАР ON ТОВАР.код = ПРОДАЖА.товар
GROUP BY час
ORDER BY час;
