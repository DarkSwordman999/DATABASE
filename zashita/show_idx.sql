-- Индексы таблиц запроса варианта
-- Запуск: ./help zas 20|22 idx
-- Пример: ./help zas 22 idx
\set QUIET on
\ir config.sql
\set QUIET off
\echo '=== Вариант' :variant': индексы таблиц' :tbls '==='
\ir indexes.sql
