-- Индексы таблиц запроса варианта (вызывается из сценариев защиты; tbls - из config.sql)
SELECT tablename AS "таблица", indexname AS "индекс", indexdef AS "определение"
  FROM pg_indexes
 WHERE schemaname = 'public' AND tablename = ANY (:'tbls'::text[])
 ORDER BY tablename, indexname;
