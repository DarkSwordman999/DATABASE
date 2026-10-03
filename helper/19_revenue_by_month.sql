-- Выручка по месяцам (аналог TAXI)
-- Запуск: ./help 19
SELECT EXTRACT(MONTH FROM ПРОДАЖА.дата)::int AS месяц, sum(ПРОДАЖА.количество * ТОВАР.цена2) AS выручка
FROM ПРОДАЖА
INNER JOIN ТОВАР ON ТОВАР.код = ПРОДАЖА.товар
GROUP BY месяц
ORDER BY месяц;
