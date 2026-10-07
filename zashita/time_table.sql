-- Таблица замеров: время в мс и в минутах; при нескольких замерах
-- минимальное время отмечено и вынесено в итоговую строку «минимум»
SELECT "замер", "время, мс", "время, мин", "отметка" FROM (
    SELECT №::text AS "замер", ms AS "время, мс", round(ms / 60000, 6) AS "время, мин",
           CASE WHEN count(*) OVER () > 1 AND ms = min(ms) OVER () THEN '<-- минимум'
                ELSE '' END AS "отметка", № AS ord
      FROM zas_время
    UNION ALL
    SELECT 'минимум', min(ms), round(min(ms) / 60000, 6), '', 1000000
      FROM zas_время HAVING count(*) > 1
) t ORDER BY ord;
SELECT min(ms) AS min_ms FROM zas_время \gset
