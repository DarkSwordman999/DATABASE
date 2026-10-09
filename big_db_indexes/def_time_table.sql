-- Таблица замеров: время в мс; при нескольких замерах
-- минимальное время отмечено и вынесено в итоговую строку «минимум»
SELECT "замер", "время, мс", "отметка" FROM (
    SELECT №::text AS "замер", ms AS "время, мс",
           CASE WHEN count(*) OVER () > 1 AND ms = min(ms) OVER () THEN '<-- минимум'
                ELSE '' END AS "отметка", № AS ord
      FROM def_время
    UNION ALL
    SELECT 'минимум', min(ms), '', 1000000
      FROM def_время HAVING count(*) > 1
) t ORDER BY ord;
SELECT min(ms) AS min_ms FROM def_время \gset
