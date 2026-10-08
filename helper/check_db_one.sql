-- Проверка одного параметра «тип значение» по базе (подключается из check_db.sql)
-- t - тип (cat, cat~, prov, prov#, goods, goods#, client#, surname, emp, emp#, district#),
-- v - значение; пустой t - нет параметра. При ошибке - сообщение, допустимые значения и abort.sql
SELECT :'t' <> '' AS has \gset
\if :has
    SELECT EXISTS (
               SELECT 1 FROM КАТЕГОРИЯ WHERE :'t' = 'cat'       AND наименование = :'v'
     UNION ALL SELECT 1 FROM КАТЕГОРИЯ WHERE :'t' = 'cat~'      AND наименование ILIKE '%' || :'v' || '%'
     UNION ALL SELECT 1 FROM ПОСТАВЩИК WHERE :'t' = 'prov'      AND название = :'v'
     UNION ALL SELECT 1 FROM ПОСТАВЩИК WHERE :'t' = 'prov#'     AND код::text = :'v'
     UNION ALL SELECT 1 FROM ТОВАР     WHERE :'t' = 'goods'     AND наименование = :'v'
     UNION ALL SELECT 1 FROM ТОВАР     WHERE :'t' = 'goods#'    AND код::text = :'v'
     UNION ALL SELECT 1 FROM КЛИЕНТ    WHERE :'t' = 'client#'   AND код::text = :'v'
     UNION ALL SELECT 1 FROM КЛИЕНТ    WHERE :'t' = 'surname'   AND фамилия = :'v'
     UNION ALL SELECT 1 FROM СОТРУДНИК WHERE :'t' = 'emp'       AND имя = :'v'
     UNION ALL SELECT 1 FROM СОТРУДНИК WHERE :'t' = 'emp#'      AND код::text = :'v'
     UNION ALL SELECT 1 FROM РАЙОН     WHERE :'t' = 'district#' AND код::text = :'v'
           ) AS ok,
           format('нет %s «%s» в таблице %s', w[1], :'v', w[2]) AS msg
      FROM (SELECT CASE :'t'
                     WHEN 'cat'       THEN '{категории,КАТЕГОРИЯ}'
                     WHEN 'cat~'      THEN '{"категории, содержащей",КАТЕГОРИЯ}'
                     WHEN 'prov'      THEN '{поставщика,ПОСТАВЩИК}'
                     WHEN 'prov#'     THEN '{"поставщика с кодом",ПОСТАВЩИК}'
                     WHEN 'goods'     THEN '{товара,ТОВАР}'
                     WHEN 'goods#'    THEN '{"товара с кодом",ТОВАР}'
                     WHEN 'client#'   THEN '{"клиента с кодом",КЛИЕНТ}'
                     WHEN 'surname'   THEN '{"клиента с фамилией",КЛИЕНТ}'
                     WHEN 'emp'       THEN '{"сотрудника с именем",СОТРУДНИК}'
                     WHEN 'emp#'      THEN '{"сотрудника с кодом",СОТРУДНИК}'
                     WHEN 'district#' THEN '{"района с кодом",РАЙОН}'
                     ELSE '{"значения неизвестного типа",?}'
                   END::text[] AS w) s \gset
    \if :ok
    \else
        \echo 'ОШИБКА:' :msg
        \echo 'Допустимые значения:'
        SELECT значение AS "значение", пояснение AS "пояснение"
          FROM (          SELECT наименование::text AS значение, ''::text AS пояснение
                            FROM КАТЕГОРИЯ WHERE :'t' IN ('cat', 'cat~')
                UNION ALL SELECT название, ''               FROM ПОСТАВЩИК WHERE :'t' = 'prov'
                UNION ALL SELECT код::text, название        FROM ПОСТАВЩИК WHERE :'t' = 'prov#'
                UNION ALL SELECT наименование, ''           FROM ТОВАР     WHERE :'t' = 'goods'
                UNION ALL SELECT код::text, наименование    FROM ТОВАР     WHERE :'t' = 'goods#'
                UNION ALL SELECT код::text, фамилия || ' ' || имя FROM КЛИЕНТ WHERE :'t' = 'client#'
                UNION ALL SELECT DISTINCT фамилия, ''       FROM КЛИЕНТ    WHERE :'t' = 'surname'
                UNION ALL SELECT DISTINCT имя, ''           FROM СОТРУДНИК WHERE :'t' = 'emp'
                UNION ALL SELECT код::text, имя             FROM СОТРУДНИК WHERE :'t' = 'emp#'
                UNION ALL SELECT код::text, название        FROM РАЙОН     WHERE :'t' = 'district#'
               ) s
         ORDER BY CASE WHEN значение ~ '^[0-9]+$' THEN lpad(значение, 10, '0') ELSE значение END;
        \ir abort.sql
    \endif
\endif
