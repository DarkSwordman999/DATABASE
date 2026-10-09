-- =====================================================================
-- Защита ЛР3, вариант 20: векторное произведение W = a × b трёхмерных векторов (тип vector3)
--   W = (ay*bz - az*by, az*bx - ax*bz, ax*by - ay*bx) - функция v3_cross, оператор #
--   (* для двух векторов уже занят скалярным произведением, которое возвращает число).
--   Показывается, что W перпендикулярен a и b: скалярные произведения W*a = 0 и W*b = 0.
-- Параметры: arg1, arg2 - векторы a и b в виде "(x,y,z)", по умолчанию (1,2,3) и (4,5,6)
-- Запуск:    ./help lr3 def 20 ["(ax,ay,az)" "(bx,by,bz)"]   (тип создаёт lab3/v20_vector3.sql)
-- Пример:    ./help lr3 def 20 "(1,0,0)" "(0,1,0)"
-- =====================================================================
\set QUIET on
SET client_min_messages TO warning;
\if :{?arg1} \else \set arg1 '' \endif
\if :{?arg2} \else \set arg2 '' \endif
SELECT coalesce(nullif(:'arg1', ''), '(1,2,3)') AS va,
       coalesce(nullif(:'arg2', ''), '(4,5,6)') AS vb \gset
-- проверка параметров: оба - корректные векторы домена vector3
SELECT CASE WHEN NOT pg_input_is_valid(:'va', 'vector3')
              THEN format('вектор a «%s» - нужно (x,y,z), три конечных числа (дробная часть через точку)', :'va')
            WHEN NOT pg_input_is_valid(:'vb', 'vector3')
              THEN format('вектор b «%s» - нужно (x,y,z), три конечных числа (дробная часть через точку)', :'vb')
            ELSE '' END AS err \gset
SELECT :'err' <> '' AS bad \gset
\if :bad
    \echo 'ОШИБКА:' :err
    \echo 'Пример: ./help lr3 def 20 "(1,2,3)" "(4,5,6)"'
    \ir ../helper/abort.sql
\endif

-- векторное произведение a × b -> vector3
CREATE OR REPLACE FUNCTION v3_cross(a vector3, b vector3) RETURNS vector3 AS $$
  SELECT ROW(a.y * b.z - a.z * b.y,
             a.z * b.x - a.x * b.z,
             a.x * b.y - a.y * b.x)::vector3
$$ LANGUAGE sql IMMUTABLE STRICT;
DROP OPERATOR IF EXISTS # (vector3, vector3);
CREATE OPERATOR # (leftarg = vector3, rightarg = vector3, procedure = v3_cross);
\set QUIET off

\echo '=============================================================================='
\echo 'ВАРИАНТ 20. Векторное произведение W = a × b (оператор #), проверка W*a = 0 и W*b = 0'
\echo '=============================================================================='
\echo 'Функция и оператор (файл lab3/def_v20_cross.sql):'
\sf v3_cross
SELECT oprname AS "оператор", oprleft::regtype AS "левый", oprright::regtype AS "правый",
       oprresult::regtype AS "результат", oprcode AS "функция"
  FROM pg_operator WHERE oprname IN ('#', '*') AND oprleft = 'vector3'::regtype
   AND oprright = 'vector3'::regtype ORDER BY 1;

\set h1 '1) Заданные векторы: a = ' :va ', b = ' :vb
\echo :h1
SELECT a, b, a # b AS "W = a × b",
       (a # b) * a AS "W*a", (a # b) * b AS "W*b",
       round(((a # b) * a)::numeric, 10) = 0
         AND round(((a # b) * b)::numeric, 10) = 0 AS "W*a = 0 и W*b = 0"
  FROM (SELECT :'va'::vector3 AS a, :'vb'::vector3 AS b) t;

\echo '2) Набор векторов: базисные, отрицательные, коллинеарные, нулевой, дробные координаты'
\echo '   (дробные координаты в double дают погрешность порядка 1e-15, поэтому W*a и W*b'
\echo '    показаны и как есть, и округлёнными до 10 знаков)'
\set QUIET on
CREATE TEMP TABLE def_pairs (№ serial, a vector3, b vector3);
INSERT INTO def_pairs (a, b) VALUES
  ((1,0,0), (0,1,0)), ((0,1,0), (0,0,1)), ((0,0,1), (1,0,0)),
  ((1,2,3), (4,5,6)), ((3,-4,0), (-2,5,1.5)), ((2,4,6), (1,2,3)),
  ((0,0,0), (7,-1,2)), ((-1,-2,-3), (3,2,1)), ((0.1,0.2,0.3), (1.5,-2.25,0.75)),
  ((1e6,-3,2), (5,1e-3,-7));
\set QUIET off
SELECT №, a, b, v3_round(a # b, 6) AS "W = a × b",
       (a # b) * a AS "W*a", (a # b) * b AS "W*b",
       round(((a # b) * a)::numeric, 10) + 0 AS "W*a (10 зн.)",
       round(((a # b) * b)::numeric, 10) + 0 AS "W*b (10 зн.)"
  FROM def_pairs ORDER BY №;

\echo '3) Свойства: b × a = -(a × b), |a × b| = |a|·|b|·sin(угла), a × a = 0'
SELECT №, a # b AS "a × b", b # a AS "b × a", b # a = -(a # b) AS "b×a = -(a×b)",
       round((@ (a # b))::numeric, 6) AS "|a × b|",
       CASE WHEN @ a > 0 AND @ b > 0 THEN
            round((@ a * @ b * sin(acos(greatest(-1, least(1, (a * b) / (@ a * @ b))))))::numeric, 6)
       END AS "|a|·|b|·sin",
       a # a AS "a × a"
  FROM def_pairs WHERE № <= 6 ORDER BY №;

\echo '4) Проверка на 10 000 случайных пар векторов'
SELECT 'целые координаты из [-100000, 100000]' AS "векторы", count(*) AS "пар",
       count(*) FILTER (WHERE (a # b) * a <> 0 OR (a # b) * b <> 0) AS "W*a или W*b не 0",
       max(greatest(abs((a # b) * a), abs((a # b) * b))) AS "max |W*a|, |W*b|"
  FROM (SELECT ROW(floor(random() * 200001) - 100000, floor(random() * 200001) - 100000,
                   floor(random() * 200001) - 100000)::vector3 AS a,
               ROW(floor(random() * 200001) - 100000, floor(random() * 200001) - 100000,
                   floor(random() * 200001) - 100000)::vector3 AS b
          FROM generate_series(1, 10000)) t
UNION ALL
SELECT 'дробные координаты из [-1, 1]', count(*),
       count(*) FILTER (WHERE abs((a # b) * a) > 1e-12 OR abs((a # b) * b) > 1e-12),
       max(greatest(abs((a # b) * a), abs((a # b) * b)))
  FROM (SELECT ROW(random() * 2 - 1, random() * 2 - 1, random() * 2 - 1)::vector3 AS a,
               ROW(random() * 2 - 1, random() * 2 - 1, random() * 2 - 1)::vector3 AS b
          FROM generate_series(1, 10000)) t;
\echo 'Итог: W = a × b перпендикулярен обоим векторам - W*a = 0 и W*b = 0 (для целых координат'
\echo 'точно, для дробных - с погрешностью вычислений в double порядка 1e-16).'
