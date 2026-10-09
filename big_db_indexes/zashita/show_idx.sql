-- Индексы таблиц запроса варианта
-- Запуск: ./help lr2 def 20|22 idx
-- Пример: ./help lr2 def 22 idx
\set QUIET on
\ir config.sql
\set QUIET off
\echo '=== Вариант' :variant': индексы таблиц' :tbls '==='
\ir indexes.sql
