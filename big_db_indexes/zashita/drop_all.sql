-- Удаление ВСЕХ индексов таблиц запроса варианта, включая индексы первичных ключей
-- (ограничения PRIMARY KEY / UNIQUE удаляются вместе со своими индексами)
SELECT set_config('def.tables', :'tbls', false) AS none \gset
DO $$
DECLARE r record;
BEGIN
    FOR r IN SELECT c.conrelid::regclass AS tbl, c.conname
               FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid
              WHERE c.contype IN ('p', 'u')
                AND t.relname = ANY (current_setting('def.tables')::text[]) LOOP
        EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', r.tbl, r.conname);
    END LOOP;
    FOR r IN SELECT i.indexrelid::regclass AS idx
               FROM pg_index i JOIN pg_class t ON t.oid = i.indrelid
              WHERE t.relname = ANY (current_setting('def.tables')::text[]) LOOP
        EXECUTE format('DROP INDEX %s', r.idx);
    END LOOP;
END $$;
