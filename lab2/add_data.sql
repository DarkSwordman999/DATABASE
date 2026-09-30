-- ЛР2, этап 1: замена содержимого ПРОДАЖА псевдослучайными записями (аналог add_data_04)
-- Запуск: ./h lr2 gen [число_записей]   (по умолчанию 2 000 000)
--         s.bat lab2\add_data.sql [число_записей]
-- Диапазоны значений берутся из исходных данных ЛР1 (DATA/SOURCE/sales),
-- поэтому сценарий можно запускать повторно.
-- 2 млн записей подобраны так, чтобы запрос (*) выполнялся 0.5-10 с (замеры: в.20 ~4.7 с, в.22 ~6.5 с)
\set ON_ERROR_STOP on
\if :{?arg1} \else \set arg1 '' \endif
SELECT CASE WHEN :'arg1' > '' THEN :'arg1' ELSE '2000000' END AS "MM" \gset
\set seed 0.23517
SET datestyle TO 'ISO, DMY';

-- 1) исходные продажи ЛР1 - база для диапазонов значений
CREATE TEMP TABLE продажа_лр1 (LIKE ПРОДАЖА);
\copy продажа_лр1 FROM 'DATA/SOURCE/sales' DELIMITER E'\t' ENCODING 'UTF8'

-- 2) параметры: d1 - мин. год, dy - число лет, mq - макс. количество, коды справочников
SELECT min(extract(year FROM дата))::int                 AS d1,
       (max(extract(year FROM дата)) - min(extract(year FROM дата)) + 1)::int AS dy,
       max(количество)                                  AS mq
  FROM продажа_лр1 \gset
SELECT max(код) AS ms FROM МАГАЗИН \gset
SELECT max(код) AS mg FROM ТОВАР \gset
SELECT max(код) AS mc FROM КЛИЕНТ \gset
\echo 'MM=':MM '  d1=':d1 '  dy=':dy '  mq=':mq '  ms=':ms '  mg=':mg '  mc=':mc

-- 3) инициализация генератора псевдослучайных чисел
SELECT setseed(:seed) AS none \gset

-- 4) новые данные
\timing on
TRUNCATE ПРОДАЖА;
INSERT INTO ПРОДАЖА SELECT
  make_date(:d1, 1, 1) + make_interval(years => floor(random()*:dy)::int,
                                       days  => floor(random()*365)::int,
                                       secs  => floor(random()*86400)::int) AS дата,
  floor(random()*:ms + 1)::int AS магазин,
  floor(random()*:mg + 1)::int AS товар,
  floor(random()*:mq + 1)::int AS количество,
  floor(random()*:mc + 1)::int AS клиент
FROM generate_series(1, :MM);
ANALYZE ПРОДАЖА;
\timing off

SELECT count(*)                                    AS "строк ПРОДАЖА",
       min(дата)::date                             AS "мин. дата",
       max(дата)::date                             AS "макс. дата",
       sum(количество)                             AS "сумма количества",
       pg_size_pretty(pg_total_relation_size('ПРОДАЖА')) AS "размер"
  FROM ПРОДАЖА;
