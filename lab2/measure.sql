-- ЛР2, этап 4: протокол измерений (аналог results.txt)
-- Запрос к ПРОДАЖА, связанной с таблицей-справочником варианта, выполняется EXPLAIN ANALYZE
-- при всех сочетаниях индексов:
--   индекс ПРОДАЖА по полю-ссылке: btree | hash | нет
--   индекс справочника по ключу (PRIMARY KEY): btree | нет
--   запрос без условия WHERE и с условием WHERE на поле справочника
-- Для каждого сочетания - 1 прогревочный и arg2 (по умолчанию 3) учитываемых прогонов.
-- Протокол выводится в консоль и в results/lr2_vNN_results.txt.
-- После замеров восстанавливается исходное состояние: индекса в ПРОДАЖА нет, PRIMARY KEY есть.
-- Запуск: ./help lr2 measure 20|22 [прогонов]      s.bat lab2\measure.sql 20 3
-- Пример: ./help lr2 measure 22 3
\set ON_ERROR_STOP on
\set QUIET on
\ir config.sql
\if :{?arg2} \else \set arg2 '' \endif
SELECT CASE WHEN :'arg2' ~ '^[1-9][0-9]*$' THEN :'arg2' ELSE '3' END AS runs \gset
\set outfile results/lr2_v :variant _results.txt

-- стоимость (Total Cost) и время выполнения (Execution Time) запроса q
CREATE OR REPLACE FUNCTION pg_temp.lr2_explain(q text, OUT cost numeric, OUT ms numeric) AS $$
DECLARE p json;
BEGIN
    EXECUTE 'EXPLAIN (ANALYZE, FORMAT JSON) ' || q INTO p;
    cost := (p -> 0 -> 'Plan' ->> 'Total Cost')::numeric;
    ms   := round((p -> 0 ->> 'Execution Time')::numeric, 1);
END $$ LANGUAGE plpgsql;

CREATE TEMP TABLE lr2_замеры (
    № serial, индекс_п text, индекс_т text, условие text, прогон int, cost numeric, ms numeric
);

-- все сочетания индексов; индексы пересоздаются командами DDL внутри функции
CREATE OR REPLACE FUNCTION pg_temp.lr2_measure(ref_table text, ref_fk text, ref_pk text,
                                               idx_name text, q text, w text, runs int)
RETURNS void AS $$
DECLARE
    ip text; pk boolean; cond text; qq text; i int; r record;
BEGIN
    FOREACH ip IN ARRAY ARRAY['btree', 'hash', ''] LOOP
        EXECUTE format('DROP INDEX IF EXISTS %I', idx_name);
        IF ip > '' THEN
            EXECUTE format('CREATE INDEX %I ON ПРОДАЖА USING %s (%I)', idx_name, ip, ref_fk);
        END IF;
        FOREACH pk IN ARRAY ARRAY[true, false] LOOP
            EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', ref_table, ref_pk);
            IF pk THEN
                EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I PRIMARY KEY (код)', ref_table, ref_pk);
            END IF;
            EXECUTE format('ANALYZE %I', ref_table);
            FOREACH cond IN ARRAY ARRAY['', w] LOOP
                qq := q || ' ' || cond;
                PERFORM pg_temp.lr2_explain(qq);            -- прогрев кэша
                FOR i IN 1..runs LOOP
                    r := pg_temp.lr2_explain(qq);
                    INSERT INTO lr2_замеры (индекс_п, индекс_т, условие, прогон, cost, ms)
                    VALUES (ip, CASE WHEN pk THEN 'btree' ELSE '' END,
                            CASE WHEN cond > '' THEN 'WHERE' ELSE '' END, i, r.cost, r.ms);
                END LOOP;
            END LOOP;
        END LOOP;
    END LOOP;
    -- исходное состояние
    EXECUTE format('DROP INDEX IF EXISTS %I', idx_name);
    EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', ref_table, ref_pk);
    EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I PRIMARY KEY (код)', ref_table, ref_pk);
END $$ LANGUAGE plpgsql;

\echo 'Вариант' :variant ': замеры выполняются, это займёт несколько минут...'
SELECT pg_temp.lr2_measure(:'ref_table', :'ref_fk', :'ref_pk', :'idx_name',
                           :'join_query', :'where_cond', :runs);

SELECT count(*) AS "M" FROM ПРОДАЖА \gset
SELECT pg_size_pretty(pg_relation_size('ПРОДАЖА')) AS "size" \gset
SELECT version() AS "pgver" \gset
\set QUIET off

\o :outfile
\pset footer off
\qecho 'ЛР2. Протокол измерений. Вариант' :variant ', таблица-справочник' :ref_table
\qecho :pgver
\qecho 'M =' :M 'записей в ПРОДАЖА, размер таблицы' :size
\qecho 'Индекс П - индекс ПРОДАЖА по полю' :ref_fk ', Индекс Т - индекс' :ref_table 'по ключу (PRIMARY KEY)'
\qecho
\qecho 'EXPLAIN ANALYZE' :join_query ';'
\qecho 'EXPLAIN ANALYZE' :join_query :where_cond ';'
\qecho
SELECT индекс_п AS "Индекс П", индекс_т AS "Индекс Т", условие AS "WHERE",
       cost, string_agg(ms || ' ms', '  ' ORDER BY прогон) AS "time",
       round(avg(ms), 1) AS "среднее, ms"
  FROM lr2_замеры
 GROUP BY индекс_п, индекс_т, условие, cost
 ORDER BY min(№);
\o
\pset footer on
\echo 'Протокол записан в' :outfile
\ir idx_names.sql
