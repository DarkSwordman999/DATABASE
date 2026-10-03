-- Изменить розничную цену товара (аналог TAXI 40: обновить госномер)
-- arg1 - код товара, arg2 - новая цена2
-- Запуск: ./help 40 1 360
UPDATE ТОВАР SET цена2 = :'arg2'::numeric WHERE код = :'arg1'::int;
SELECT * FROM ТОВАР WHERE код = :'arg1'::int;
