-- Защита ЛР2: настройки варианта по первому параметру (20 или 22, по умолчанию 20)
-- arg2, arg3 - параметры запроса: в.20 - названия двух поставщиков, в.22 - категория товара
\if :{?arg1} \else \set arg1 '' \endif
\if :{?arg2} \else \set arg2 '' \endif
\if :{?arg3} \else \set arg3 '' \endif
SELECT CASE WHEN :'arg1' IN ('20', '22') THEN :'arg1' ELSE '20' END AS variant \gset
SELECT :'variant' = '20' AS is_v20 \gset
\set explain ''
SET client_min_messages TO warning;
\if :is_v20
    -- в.20: таблицы ПРОДАЖА, ТОВАР, ПОСТАВЩИК; в п. 3 запрос выполняется один раз
    SELECT coalesce(nullif(:'arg2', ''), 'ООО Турман') AS p1,
           coalesce(nullif(:'arg3', ''), 'ЧП Загорье') AS p2 \gset
    \set tbls '{ПРОДАЖА,ТОВАР,ПОСТАВЩИК}'
    \set query_file v20_query.sql
\else
    -- в.22: таблицы ПРОДАЖА, ТОВАР, КАТЕГОРИЯ; в п. 3 запрос выполняется 5 раз
    SELECT coalesce(nullif(:'arg2', ''), 'мебель') AS p1 \gset
    \set p2 ''
    \set tbls '{ПРОДАЖА,ТОВАР,КАТЕГОРИЯ}'
    \set query_file v22_query.sql
\endif
SELECT count(*) < 100000 AS small FROM ПРОДАЖА \gset
\if :small
    \echo 'ВНИМАНИЕ: в ПРОДАЖА меньше 100 000 записей - сначала ./help lr2 gen (2 млн записей)'
\endif
