-- Выручка по дням недели (аналог TAXI)
-- Запуск: ./help 25
SELECT EXTRACT(ISODOW FROM ПРОДАЖА.дата)::int AS "№",
       (ARRAY['пн','вт','ср','чт','пт','сб','вс'])[EXTRACT(ISODOW FROM ПРОДАЖА.дата)::int] AS "день недели",
       count(*) AS продаж, round(sum(ПРОДАЖА.количество * ТОВАР.цена2), 2) AS выручка
FROM ПРОДАЖА
INNER JOIN ТОВАР ON ТОВАР.код = ПРОДАЖА.товар
GROUP BY 1, 2
ORDER BY 1;
