-- ЛР2, этап 3: индексы таблицы ПРОДАЖА и таблицы-справочника варианта (аналог idx_names)
-- Показывает как созданные пользователем индексы, так и автоматические (для PRIMARY KEY)
-- Запуск: ./h lr2 idx 20|22      s.bat lab2\idx_names.sql 20
\set QUIET on
\ir config.sql
\set QUIET off
SELECT tablename AS "таблица", indexname AS "индекс", indexdef AS "определение"
  FROM pg_indexes
 WHERE tablename IN ('ПРОДАЖА', :'ref_table')
 ORDER BY tablename, indexname;
