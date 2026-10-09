-- Средний чек по часам дня (аналог TAXI)
-- Запуск: ./help 29
SELECT EXTRACT(HOUR FROM ПРОДАЖА.дата)::int AS час, round(avg(ПРОДАЖА.количество * ТОВАР.цена2), 2) AS "средний чек"
FROM ПРОДАЖА
INNER JOIN ТОВАР ON ТОВАР.код = ПРОДАЖА.товар
GROUP BY час
ORDER BY час;
