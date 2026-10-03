-- Функция задачи 2: выручка по категориям и временам года (аналог TAXI revenue_by_class_and_season)
-- Вызов: SELECT * FROM revenue_by_category_and_season();   ./help 202
CREATE OR REPLACE FUNCTION revenue_by_category_and_season()
RETURNS TABLE (категория varchar, время_года text, продаж bigint, выручка numeric) AS $$
DECLARE
    сезоны text[] := ARRAY['зима','зима','весна','весна','весна','лето','лето','лето',
                           'осень','осень','осень','зима'];
BEGIN
    RETURN QUERY
    SELECT КАТЕГОРИЯ.наименование, сезоны[EXTRACT(MONTH FROM ПРОДАЖА.дата)::int],
           count(*), sum(ПРОДАЖА.количество * ТОВАР.цена2)
    FROM ПРОДАЖА
    INNER JOIN ТОВАР     ON ТОВАР.код = ПРОДАЖА.товар
    INNER JOIN КАТЕГОРИЯ ON КАТЕГОРИЯ.код = ТОВАР.категория
    GROUP BY 1, 2
    ORDER BY 1, array_position(ARRAY['зима','весна','лето','осень'], сезоны[EXTRACT(MONTH FROM ПРОДАЖА.дата)::int]);
END $$ LANGUAGE plpgsql STABLE;
