-- Распределение продаж по часам в процентах (оконная функция, аналог TAXI)
-- Запуск: ./help 28
SELECT EXTRACT(HOUR FROM дата)::int AS час, count(*) AS продаж,
       round(count(*) * 100.0 / sum(count(*)) OVER (), 2) AS "доля, %"
FROM ПРОДАЖА
GROUP BY час
ORDER BY час;
