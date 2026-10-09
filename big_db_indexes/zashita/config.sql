-- Защита ЛР2: настройки варианта по первому параметру (20 или 22, по умолчанию 20)
-- arg2, arg3 - параметры запроса: в.20 - названия двух поставщиков, в.22 - категория товара
-- Пример: ./help zas 20 1 "ООО Турман" "ЧП Загорье"  (arg1 = 20, arg2, arg3 - поставщики)
-- Результат: variant, is_v20, p1, p2, tbls (таблицы запроса), q (текст запроса),
--            q_file (файл с текстом запроса)
\if :{?arg1} \else \set arg1 '' \endif
\if :{?arg2} \else \set arg2 '' \endif
\if :{?arg3} \else \set arg3 '' \endif
SELECT CASE WHEN :'arg1' IN ('20', '22') THEN :'arg1' ELSE '20' END AS variant \gset
SELECT :'variant' = '20' AS is_v20 \gset
SET client_min_messages TO warning;
\pset footer off
\if :is_v20
    -- в.20: таблицы ПРОДАЖА, ТОВАР, ПОСТАВЩИК
    SELECT coalesce(nullif(:'arg2', ''), 'ООО Турман') AS p1,
           coalesce(nullif(:'arg3', ''), 'ЧП Загорье') AS p2 \gset
    -- проверка параметров: оба поставщика есть в ПОСТАВЩИК и не совпадают
    SELECT CASE
             WHEN NOT EXISTS (SELECT 1 FROM ПОСТАВЩИК WHERE название = :'p1')
               THEN format('поставщик «%s» не найден в таблице ПОСТАВЩИК', :'p1')
             WHEN NOT EXISTS (SELECT 1 FROM ПОСТАВЩИК WHERE название = :'p2')
               THEN format('поставщик «%s» не найден в таблице ПОСТАВЩИК', :'p2')
             WHEN :'p1' = :'p2'
               THEN 'укажите двух разных поставщиков'
             ELSE ''
           END AS err \gset
    SELECT :'err' <> '' AS bad \gset
    \if :bad
        \echo 'ОШИБКА:' :err
        \echo 'Допустимые поставщики (пример: ./help zas 20 1 "ООО Турман" "ЧП Загорье"):'
        SELECT название AS "поставщик" FROM ПОСТАВЩИК ORDER BY название;
        \ir ../../helper/abort.sql
    \endif
    \set tbls '{ПРОДАЖА,ТОВАР,ПОСТАВЩИК}'
    \set q_file big_db_indexes/zashita/v20_query.sql
    \ir v20_query.sql
\else
    -- в.22: таблицы ПРОДАЖА, ТОВАР, КАТЕГОРИЯ
    SELECT coalesce(nullif(:'arg2', ''), 'мебель') AS p1 \gset
    \set p2 ''
    -- проверка параметра: категория есть в КАТЕГОРИЯ, второго параметра нет
    SELECT CASE
             WHEN :'arg3' <> ''
               THEN format('для в.22 нужен один параметр - категория, лишний: «%s»', :'arg3')
             WHEN NOT EXISTS (SELECT 1 FROM КАТЕГОРИЯ WHERE наименование = :'p1')
               THEN format('категория «%s» не найдена в таблице КАТЕГОРИЯ', :'p1')
             ELSE ''
           END AS err \gset
    SELECT :'err' <> '' AS bad \gset
    \if :bad
        \echo 'ОШИБКА:' :err
        \echo 'Допустимые категории (пример: ./help zas 22 1 мебель):'
        SELECT наименование AS "категория" FROM КАТЕГОРИЯ ORDER BY наименование;
        \ir ../../helper/abort.sql
    \endif
    \set tbls '{ПРОДАЖА,ТОВАР,КАТЕГОРИЯ}'
    \set q_file big_db_indexes/zashita/v22_query.sql
    \ir v22_query.sql
\endif
\if :{?check_only}
    \quit
\endif
SELECT count(*) < 100000 AS small FROM ПРОДАЖА \gset
\if :small
    \echo 'ВНИМАНИЕ: в ПРОДАЖА меньше 100 000 записей - сначала ./help lr2 gen (2 млн записей)'
\endif
