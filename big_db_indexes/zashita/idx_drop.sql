-- Защита ЛР2: удаление индексов задания 3 своего варианта (def20_* / def22_*) с таблиц запроса;
-- прочие индексы и PRIMARY KEY не трогаются (все индексы удаляет drop_all.sql в заданиях 2 и 3)
-- Запуск: ./help lr2 def 20|22 idx_drop
-- Пример: ./help lr2 def 20 idx_drop      ./help lr2 def 22 idx_drop
\set QUIET on
\ir config.sql
\set QUIET off
\set msg 'Вариант ' :variant ': удаление индексов задания 3 (def' :variant '_*) с таблиц ' :tbls
\echo :msg
SELECT set_config('def.tables', :'tbls', false) AS none,
       set_config('def.own', 'def' || :'variant' || '\_%', false) AS none2 \gset
DO $$
DECLARE r record;
BEGIN
    FOR r IN SELECT i.indexrelid::regclass AS idx
               FROM pg_index i
                    JOIN pg_class t  ON t.oid = i.indrelid
                    JOIN pg_class ic ON ic.oid = i.indexrelid
              WHERE t.relname = ANY (current_setting('def.tables')::text[])
                AND ic.relname LIKE current_setting('def.own') LOOP
        EXECUTE format('DROP INDEX %s', r.idx);
    END LOOP;
END $$;
\ir indexes.sql
