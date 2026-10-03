-- Таблица замеров: время в мс и в минутах, минимальное время отмечено
SELECT № AS "замер",
       ms AS "время, мс",
       round(ms / 60000, 6) AS "время, мин",
       to_char(make_interval(secs => ms / 1000), 'MI:SS.MS') AS "мин:сек.мс",
       CASE WHEN ms = min(ms) OVER () THEN '<-- минимум' ELSE '' END AS "отметка"
  FROM zas_время ORDER BY №;
SELECT min(ms) AS min_ms, round(min(ms) / 60000, 6) AS min_min FROM zas_время \gset
\echo 'Минимальное время:' :min_ms 'мс =' :min_min 'мин'
