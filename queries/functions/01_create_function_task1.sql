-- Функция задачи 1: магазины с выручкой выше порога (аналог TAXI drivers_above_revenue)
-- Вызов: SELECT * FROM shops_above_revenue(100000);   ./help 201 100000
CREATE OR REPLACE FUNCTION shops_above_revenue(порог numeric)
RETURNS TABLE (магазин varchar, продаж bigint, выручка numeric) AS $$
    SELECT МАГАЗИН.название, count(*), sum(ПРОДАЖА.количество * ТОВАР.цена2)
    FROM ПРОДАЖА
    INNER JOIN ТОВАР   ON ТОВАР.код = ПРОДАЖА.товар
    INNER JOIN МАГАЗИН ON МАГАЗИН.код = ПРОДАЖА.магазин
    GROUP BY МАГАЗИН.название
    HAVING sum(ПРОДАЖА.количество * ТОВАР.цена2) > порог
    ORDER BY 3 DESC;
$$ LANGUAGE sql STABLE;
