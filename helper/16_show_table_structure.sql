-- Структура таблиц базы SALES (аналог TAXI: структура таблиц)
-- Запуск: ./help 16
SELECT t.relname AS таблица, a.attname AS поле, format_type(a.atttypid, a.atttypmod) AS тип,
       CASE WHEN a.attnotnull THEN 'нет' ELSE 'да' END AS "NULL допустим",
       CASE WHEN EXISTS (SELECT 1 FROM pg_constraint k
                          WHERE k.conrelid = t.oid AND k.contype = 'p' AND a.attnum = ANY (k.conkey))
            THEN 'PRIMARY KEY' ELSE '' END AS ключ
FROM pg_attribute a
     JOIN pg_class t     ON t.oid = a.attrelid
     JOIN pg_namespace n ON n.oid = t.relnamespace AND n.nspname = 'public'
WHERE a.attnum > 0 AND NOT a.attisdropped
  AND t.relname IN ('РАЙОН', 'КАТЕГОРИЯ', 'ПОСТАВЩИК', 'ТОВАР', 'МАГАЗИН',
                    'СОТРУДНИК', 'КЛИЕНТ', 'РАБОТА', 'ПОСТАВКА', 'ПРОДАЖА')
ORDER BY array_position(ARRAY['РАЙОН', 'КАТЕГОРИЯ', 'ПОСТАВЩИК', 'ТОВАР', 'МАГАЗИН',
                              'СОТРУДНИК', 'КЛИЕНТ', 'РАБОТА', 'ПОСТАВКА', 'ПРОДАЖА']::text[],
                        t.relname::text), a.attnum;
