-- Функция задачи 3: сводная таблица выручки магазины x категории (аналог TAXI display_pivot_table)
-- Столбцы категорий формируются по таблице КАТЕГОРИЯ (мебель, одежда)
-- Вызов: SELECT * FROM display_pivot_table();   ./help 203
CREATE OR REPLACE FUNCTION display_pivot_table()
RETURNS TABLE (магазин varchar, мебель numeric, одежда numeric, итого numeric) AS $$
    SELECT МАГАЗИН.название,
           coalesce(sum(ПРОДАЖА.количество * ТОВАР.цена2) FILTER (WHERE КАТЕГОРИЯ.наименование = 'мебель'), 0),
           coalesce(sum(ПРОДАЖА.количество * ТОВАР.цена2) FILTER (WHERE КАТЕГОРИЯ.наименование = 'одежда'), 0),
           coalesce(sum(ПРОДАЖА.количество * ТОВАР.цена2), 0)
    FROM МАГАЗИН
    LEFT JOIN ПРОДАЖА   ON ПРОДАЖА.магазин = МАГАЗИН.код
    LEFT JOIN ТОВАР     ON ТОВАР.код = ПРОДАЖА.товар
    LEFT JOIN КАТЕГОРИЯ ON КАТЕГОРИЯ.код = ТОВАР.категория
    GROUP BY МАГАЗИН.код, МАГАЗИН.название
    ORDER BY МАГАЗИН.код;
$$ LANGUAGE sql STABLE;
