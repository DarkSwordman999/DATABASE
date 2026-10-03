-- Структура таблиц базы SALES (аналог TAXI: структура таблиц)
-- Запуск: ./help 16
SELECT table_name AS таблица, column_name AS поле, data_type AS тип,
       coalesce(character_maximum_length::text, numeric_precision || ',' || numeric_scale, '') AS размер,
       is_nullable AS null_допустим
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('РАЙОН', 'КАТЕГОРИЯ', 'ПОСТАВЩИК', 'ТОВАР', 'МАГАЗИН',
                     'СОТРУДНИК', 'КЛИЕНТ', 'РАБОТА', 'ПОСТАВКА', 'ПРОДАЖА')
ORDER BY array_position(ARRAY['РАЙОН', 'КАТЕГОРИЯ', 'ПОСТАВЩИК', 'ТОВАР', 'МАГАЗИН',
                              'СОТРУДНИК', 'КЛИЕНТ', 'РАБОТА', 'ПОСТАВКА', 'ПРОДАЖА']::text[],
                        table_name::text), ordinal_position;
