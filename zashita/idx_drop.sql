-- Защита ЛР2: удаление индексов задания 3 (zas_*) с таблиц запроса варианта;
-- прочие индексы и PRIMARY KEY не трогаются (все индексы удаляет drop_all.sql в заданиях 2 и 3)
-- Запуск: ./help zas 20|22 idx_drop
-- Пример: ./help zas 20 idx_drop      ./help zas 22 idx_drop
\set QUIET on
\ir config.sql
\set QUIET off
\echo 'Вариант' :variant': удаление индексов задания 3 (zas_*) с таблиц' :tbls
SELECT set_config('zas.tables', :'tbls', false) AS none \gset
DO $$
DECLARE r record;
BEGIN
    FOR r IN SELECT i.indexrelid::regclass AS idx
               FROM pg_index i
                    JOIN pg_class t  ON t.oid = i.indrelid
                    JOIN pg_class ic ON ic.oid = i.indexrelid
              WHERE t.relname = ANY (current_setting('zas.tables')::text[])
                AND ic.relname LIKE 'zas\_%' LOOP
        EXECUTE format('DROP INDEX %s', r.idx);
    END LOOP;
END $$;
\ir indexes.sql
